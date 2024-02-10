#!/usr/bin/python3

import requests, json, urllib
from datetime import datetime
from collections import OrderedDict
from os.path import splitext
import fnmatch, os


def get_key(name, pkginfo):
	"""
	This function looks first in github block, and then in the main block for a specific key.

	We use this for things that we initially designed to be in the main block but make a lot
	more sense being in the gitlab block.
	@note: it is literaly function from github.py
	"""
	if name in pkginfo["gitlab"]:
		return pkginfo["gitlab"][name]
	elif name in pkginfo:
		return pkginfo[name]
	else:
		return None


ARCHIVE_PRIORITIES = { # lower value - higher priority
    "tar.bz2" : 0,
    "tar.gz" : 1,
    "zip" : 2,
    "tar" : 3,

}


def getBestSource(sources):
	"""
 Get Best source from graphql response.
 by documentation the tar.bz2, tar.gz, zip and tar are always generated (https://docs.gitlab.com/ee/user/project/releases/release_fields.html) and have same order, but you can never be sure if it will be always true
 """
	global ARCHIVE_PRIORITIES
	srs = sources['nodes']
	s = sorted(srs,
	           key=lambda x: ARCHIVE_PRIORITIES[x['format']])  # sorted archives
	return s[0]


"""
Short notes on graphql: "GraphQL is an open-source data query and manipulation language for APIs" and nothing more, literaly nothing more.
Only query functionality is in specification (you can choice with field want to get) without any filtering functionality. Anything fancier than field query need to be done by implementation... (for example: filter operation :( )

As for executing api it just plain json post object with two keys:
  1. "query" - the query instruction
  2. "variables" (optional) - variables to query

For example:
query :
```
query($cursor_pos: String) {
  
  queryComplexity {
    score
    limit
  }
  project(fullPath: "gitlab-org/gitlab") {
    releases(sort: RELEASED_AT_DESC,first : 10,after:$cursor_pos) {
      pageInfo {
        endCursor
        hasNextPage
      }
      
      nodes {

        tagName
        createdAt
      }
      
    }
  }
}
```

variables:
```
{ "cursor_pos": "eyJyZWxlYXNlZF9hdCI6IjIwMjItMDQtMjIgMDA6MDA6MDAuMDAwMDAwMDAwICswMDAwIiwiaWQiOiI0NzUxNDQzIn0" }
```

becomes: {"query":"query($cursor_pos: String) {\n  \n  queryComplexity {\n    score\n    limit\n  }\n  project(fullPath: \"gitlab-org/gitlab\") {\n    releases(sort: RELEASED_AT_DESC,first : 10,after:$cursor_pos) {\n      pageInfo {\n        endCursor\n        hasNextPage\n      }\n      \n      nodes {\n\n        tagName\n        createdAt\n      }\n      \n    }\n  }\n}\n\n","variables":{"cursor_pos":"eyJyZWxlYXNlZF9hdCI6IjIwMjItMDQtMjIgMDA6MDA6MDAuMDAwMDAwMDAwICswMDAwIiwiaWQiOiI0NzUxNDQzIn0"}}
and it is posted to api endpoint.


"""

# query project releases (this query is for filter) and collect all assets, links
QUERY_RELEASES = """query ($project_path: ID!, $cursor_pos: String, $number_of_records: Int = 100) {
  queryComplexity {
    score
    limit
  }
  project(fullPath: $project_path) {
    releases(sort: RELEASED_AT_DESC, first: $number_of_records, after: $cursor_pos) {
      pageInfo {
        endCursor
        hasNextPage
      }
      nodes {
        tagName
        createdAt
        assets {
          sources {
            nodes {
              format
              url
            }
          }
          links {
            nodes {
              directAssetUrl
              name
              linkType
            }
          }
        }
      }
    }
  }
}
"""

# query project description, author and so on
QUERY_PROJECT_METADATA = """
query($project_path: ID!) {
  project(fullPath: $project_path) {
    id
    name
    httpUrlToRepo
    description
    webUrl
  }
}
"""


def project_metadata(endpoint, project_path):
	"""return gitlab project metadata:
     description
     httpUrlToRepo - git url
     id - project id, used by api
     name - "project name"
     webUrl - absoulute web url to project
   """
	qvars = {'project_path': project_path}

	r = requests.post(endpoint,
	                  json={
	                      "query": QUERY_PROJECT_METADATA,
	                      "variables": qvars
	                  }).json()
	r = r["data"]["project"]
	r["id"] = r["id"].split("/")[-1]

	return r


async def releases_search(endpoint,
                          project_path,
                          matcher,
                          number_of_matches=99,
                          date_cutoff=datetime(2015, 9, 1),
                          query_number_of_records=100):
	"""
  uses GraphQL api fetch releases and published resources (aka sources and other links)
  :note: This function fetch releases with pagination
  :param project_path: path to project (example: gitlab-org/gitlab, inkscape/inkscape and so on)
  :param matcher: filtering function for example hub.pkgtools.github.RegexMatcher(regex=hub.pkgtools.github.VersionMatch.GRABBY, when true consider item to list
  :param number_of_matches: after this number stop futher processing and generating requests to endpoint
  :param date_cutoff: semantic same as for number_of_matches - to not download very old releases
  :param query_number_of_records: number of records returned from server (request size)
  """
	matched = []  # matched versions
	assets = OrderedDict()  # version and assets dictonary

	num_queries = 99

	qvars = {
	    'project_path': project_path,
	    'number_of_records': query_number_of_records,
	}

	cursor_pos = None
	bail_out = False

	# iterate over release versions,
	for i in range(num_queries, -1, -1):
		qvars["cursor_pos"] = cursor_pos
		r = requests.post(endpoint,
		                  json={
		                      "query": QUERY_RELEASES,
		                      "variables": qvars
		                  }).json()

		releases = r["data"]["project"]["releases"]
		for j in releases["nodes"]:
			release_date = datetime.strptime(j["createdAt"],
			                                 '%Y-%m-%dT%H:%M:%SZ')

			if release_date < date_cutoff:
				bail_out = True
				break

			if matcher(j["tagName"]):
				matched.append(j["tagName"])

				if number_of_matches is not None and len(
				    matched) > number_of_matches:
					bail_out = True
					break
				# add files
				src_code = getBestSource(j["assets"]["sources"])
				src_code["name"] = "Source code"

				links = []

				assert len(
				    j["assets"]["links"]['nodes']
				) < 100, "parsing more than 100 links is not yet implemented"
				for v in j["assets"]["links"]['nodes']:
					#maybe check for link type, if v["linkType"] == 'PACKAGE':
					links.append({
					    'name': v["name"],
					    'url': v["directAssetUrl"]
					})
				assets[j["tagName"]] = [src_code] + links

		cursor_pos = releases["pageInfo"]["endCursor"]
		if releases["pageInfo"]["hasNextPage"] == False or bail_out:
			break

	return assets


async def query_tags(endpoint,
                     project_id,
                     matcher,
                     number_of_matches=99,
                     query_number_of_records=100):
	""" Query tags using, API endpoint
   :param endpoint: instance base url
   :param project_id: numeric project id
   :param matcher: matching function, if true add tag to list
   :param number_of_matches: number of tags to collect
   :param query_number_of_records: number of items per page
   :return: returns list with tags, sorted by date
   note: example: https://gitlab.com/api/v4/projects/278964/repository/tags?page=5 it is subject to rate limits: https://docs.gitlab.com/ee/user/admin_area/settings/user_and_ip_rate_limits.html
 """
	if not (type(project_id) == int or project_id.isdigit()):
		raise TypeError("project_id must be number")

	url_base = f"{endpoint}/api/v4/projects/{project_id}/repository/tags"

	params = {
	    'per_page': query_number_of_records,
	    'page': 1,
	}

	tags = []

	while True:
		req = requests.get(url_base, params=params)

		bail_out = False
		for i in req.json():
			#try:
				if matcher(i['name']):
					tags.append(i['name'])
					if len(tags) > number_of_matches:
						bail_out = True
						break
			#except Exception as e:
			#	import pdb
			#	pdb.set_trace()

		if len(req.headers['X-Next-Page']) == 0:
			break

		if bail_out:
			break
		params['page'] = int(req.headers['X-Next-Page'])

	return tags


def get_link_from_tag(endpoint, project_id, tag):
	# generates link from tag and endpoint
	# it is function, because some day  will possible using graphql (https://gitlab.com/gitlab-org/gitlab/-/issues/372992)
	# https://docs.gitlab.com/ee/api/repositories.html#get-file-archive

	return f"{endpoint}/api/v4/projects/{project_id}/repository/archive.tar.bz2?sha={tag}"


def generate_assets(pkg_assets, generator_fn=None, source_code_fn=None):
	""" recursive function to parse pkg_assets
 
       just iterate over container and perform following:
       1) if there are item and is name "source code" or key named "source code" execute source_code_fn function
       2) if it is string - call generator_fn
       3) if it is list, but going though list (list in list) - raise exception
       4) if it is list, but iterating over dict, then recursively call generate_assets
       5) if it is dict, then recursively call generate_assets
   """

	if type(pkg_assets) == list:
		r = []
		for i in pkg_assets:
			if type(i) == str and i.lower() == "source code":
				r.append(
				    source_code_fn() if source_code_fn else "adding source")
			elif type(i) == str:
				r.append(
				    generator_fn(i) if generator_fn else "append str source")
			elif type(i) == dict:
				r.append(generate_assets(i, generator_fn, source_code_fn))
			elif type(i) == list:
				raise RuntimeError("list in list is not supported")
		return r
	elif type(pkg_assets) == dict:
		r = {}
		for k, v in pkg_assets.items():
			if k.lower() == "source code":  # source code have special meaning
				r[k.lower()] = source_code_fn(
				) if source_code_fn else "adding source code"
			if type(v) == str:
				r[k] = generator_fn(v) if generator_fn else f"adding {v} source"
			elif type(v) == list:
				r[k] = generate_assets(v, generator_fn, source_code_fn)
			elif type(v) == dict:
				r[k] = generate_assets(v, generator_fn, source_code_fn)
		return r


def splitext_(path):
	# https://stackoverflow.com/a/37896418
	for ext in ['.tar.gz', '.tar.bz2']:
		if path.endswith(ext):
			return path[:-len(ext)], path[-len(ext):]
	return splitext(path)


# note: these warnings are for unregistred user
# warning : download endpoint is subject to 5 downloads per minute (https://docs.gitlab.com/ee/api/repositories.html#get-file-archive)
# warning : other endpoints have limits too, for rest api, someting 2000 requests per time interval (requests have weights, some queries have weight 2) - limits are published in response headers
# warning : GraphQL have complexity and request limits too, for complexity there are link (https://docs.gitlab.com/ee/api/graphql/#limits), for number of queries i guessing something like 2000 requests per interval (maybe 1 min, maybe 5 didnt notice on documentation)


async def generate(hub, **pkginfo):

	# promote "match" and "select" in pkginfo into gitlab element, so we support both inside and outside
	# this element for these keys:

	for key in ["match", "select"]:
		if key in pkginfo:
			if "gitlab" in pkginfo and key in pkginfo["gitlab"]:
				raise ValueError(
				    f"{key} defined in both main YAML block and gitlab block -- chose one."
				)
	query = get_key("query", pkginfo)
	if query not in ["releases", "tags"]:
		raise KeyError(
		    f"{pkginfo['cat']}/{pkginfo['name']} should specify GitLab query type of 'releases' or 'tags'."
		)

	# check instance and project path keys
	# logic behind:
	# if "instance" is given, "project_path" cannot be url path
	# if no "instance" field given, "project_path" must be url path

	if 'instance' in pkginfo:
		raise KeyError(
		    f"{pkginfo['cat']}/{pkginfo['name']} instance valid only in default block"
		)

	if 'instance' in pkginfo['gitlab']:
		iparsed = urllib.parse.urlparse(pkginfo['gitlab']['instance'])
		if len(iparsed.params) > 0 or len(iparsed.path) > 0 or len(
		    iparsed.query) > 0 or len(iparsed.fragment) > 0:
			raise KeyError(
			    f"{pkginfo['cat']}/{pkginfo['name']} instance can only containt hostname"
			)
		instance_url = pkginfo['gitlab']['instance']  # base instance url

		iparsed = urllib.parse.urlparse(pkginfo['project_path'])

		if len(iparsed.scheme) > 0 or len(iparsed.netloc) > 0 or len(
		    iparsed.params) > 0 or len(iparsed.query) > 0 or len(
		        iparsed.fragment) > 0:
			raise KeyError(
			    f"{pkginfo['cat']}/{pkginfo['name']} project_path cannot be url when instance is given"
			)
		project_path = pkginfo['project_path']
		if project_path[0] == '/':
			project_path = project_path[1:]

	else:  # no instance given
		iparsed = urllib.parse.urlparse(pkginfo['project_path'])
		if len(iparsed.params) > 0 or len(
		    iparsed.query) or len(iparsed.fragment) > 0:
			raise KeyError(
			    f"{pkginfo['cat']}/{pkginfo['name']} project_path can only containt hostname and path"
			)
		instance_url = f"{iparsed.scheme}://{iparsed.netloc}"
		project_path = iparsed.path[1:]  # skip first '/'

	gitlab_metadata = project_metadata(f"{instance_url}/api/graphql",
	                                   project_path)

	pkginfo["description"] = gitlab_metadata["description"]
	pkginfo["homepage"] = gitlab_metadata["webUrl"]

	if get_key("match", pkginfo):
		matcher = hub.pkgtools.github.RegexMatcher(regex=get_key("match",pkginfo))
		if matcher.regex.groups != 1:
			raise KeyError(
			    f"{pkginfo['cat']}/{pkginfo['name']} match regular expresion must contain only one regex match group (currently are {matcher.groups} groups)"
			)
	else:
		matcher = hub.pkgtools.github.RegexMatcher(
		    regex=hub.pkgtools.github.VersionMatch.GRABBY)

	if get_key("select", pkginfo):
		selector = hub.pkgtools.github.RegexMatcher(regex=get_key("select",pkginfo))
		if selector.regex.groups > 0:
			hub.pkgtools.model.log.warning(
			    f"{pkginfo['cat']}/{pkginfo['name']} select have capture group, probably is not what you want"
			)
	else:
		# filter anything which has parsable version
		selector = hub.pkgtools.github.RegexMatcher(
		    regex=hub.pkgtools.github.VersionMatch.GRABBY)

	if "version" not in pkginfo or pkginfo["version"] == 'latest':
		version = '*'
	else:
		version = pkginfo["version"]

	qtype = get_key("query", pkginfo)
	asset = None

	if not 'lstrip' in pkginfo: # add default lstrip
		pkg_lstrip = ''
	else:
		pkg_lstrip = pkginfo['lstrip']

	if qtype == "releases":
		assets = await releases_search(f"{instance_url}/api/graphql",
		                               project_path, selector.match)
		for i in assets:  # go through all versions
			m = matcher.regex.findall(i.lstrip(pkg_lstrip))
			if len(m) < 1: continue
			if len(m) > 1:  
			   hub.pkgtools.model.log.warning(
			    f"{pkginfo['cat']}/{pkginfo['name']} version match regex matched more than one regex group, using last group (matched groups {m})"
			)

			m = m[-1]
			if fnmatch.fnmatch(m, version):
				found_version = True
				version = m  # get concrete version
				asset = assets[i]  # "one" asset from assets... ¯\_(ツ)_/¯
				break
		# asset logic
		if asset is None:
			raise KeyError(
			    f"{pkginfo['cat']}/{pkginfo['name']} version `{version}` not found, possible reasons: version does not exists or gitlab-1 generator cutoff values reached: 100 releases and released not eraler than 2015-09-01."
			)

		pkginfo["version"] = version


		def asset_fn(asset_name):
			asset_name = asset_name.format(**pkginfo)  # format string
			for i in asset:
				if i['name'] == asset_name:
					iparsed = urllib.parse.urlparse(i["url"])
					final_name = os.path.basename(iparsed.path)
					if not (
					    pkginfo['version'] in final_name
					):  # there are no version in file name, add -fnt-{version}.suffix to avoid name clash
						p = splitext_(final_name)
						final_name = f"{p[0]}-fnt-{pkginfo['version']}{p[1]}"
					artifact = hub.pkgtools.ebuild.Artifact(
					    url=i["url"], final_name=final_name)
					return artifact
			raise KeyError(
			    f"{pkginfo['cat']}/{pkginfo['name']} asset '{asset_name}' not found"
			)

		def source_code_fn():
			for i in asset:
				if i["name"] == "Source code":
					return hub.pkgtools.ebuild.Artifact(url=i["url"])
			raise KeyError(
			    f"{pkginfo['cat']}/{pkginfo['name']} no source published")

		artifacts = generate_assets(pkginfo['assets'], asset_fn, source_code_fn)

		#import pdb
		#pdb.set_trace()
		ebuild = hub.pkgtools.ebuild.BreezyBuild(
		    **pkginfo,
		    artifacts=artifacts,
		)
		ebuild.push()

	elif qtype == "tags":
		tags = await query_tags(instance_url, gitlab_metadata["id"],
		                        selector.match)
		found_tag = None
		for i in tags:  # go through all versions
			m = matcher.regex.findall(i.lstrip(pkg_lstrip))
			if len(m) < 1: continue
			if len(m) > 1:  
			   hub.pkgtools.model.log.warning(
			    f"{pkginfo['cat']}/{pkginfo['name']} version match regex matched more than one regex group, using last group (matched groups {m})"
			)
			   import pdb;pdb.set_trace()
			m = m[-1]
			if fnmatch.fnmatch(m, version):
				found_tag = i
				version = m  # get concrete version
				break
		# asset logic
		if found_tag is None:
			raise KeyError(
			    f"{pkginfo['cat']}/{pkginfo['name']} version `{version}` not found, possible reasons: tag does not exists or gitlab-1 generator cutoff values reached: requested version is more than 100 tags later."
			)

		pkginfo["version"] = version

		source_link = get_link_from_tag(instance_url, gitlab_metadata["id"],
		                                found_tag)

		ebuild = hub.pkgtools.ebuild.BreezyBuild(
		    **pkginfo,
		    artifacts=[
		        hub.pkgtools.ebuild.Artifact(
		            url=source_link,
		            final_name=f"{pkginfo['name']}-{version}.tar.bz2")
		    ],
		)
		ebuild.push()


if __name__ == '__main__':  # it should have own file
	import unittest

	class gitlabv1_tests(unittest.IsolatedAsyncioTestCase):

		async def test_items_get_releases(self):
			""" test releases fetching functionality"""
			graphql_endpoint = f"https://gitlab.com/api/graphql"

			r1 = await releases_search(graphql_endpoint,
			                           "gitlab-org/gitlab",
			                           lambda x: True,
			                           number_of_matches=16
			                          )  # should get 16 items in response
			r2 = await releases_search(graphql_endpoint,
			                           "gitlab-org/gitlab",
			                           lambda x: True,
			                           number_of_matches=16,
			                           query_number_of_records=6)

			self.assertEqual(
			    r1, r2
			)  # it can fail if there is modification between r1 and r2 calls
			pass

		async def test_url_generator(self):
			""" test link generator function """

			a = [
			    'Source code', {
			        'amd64': ['package: RPM arm64', 'package: PRM i686']
			    }, {
			        'arm64': 'package: RPM arm64'
			    }
			]
			b = {
			    'Source code': True,
			    'amd64': 'package: RPM arm64',
			    'arm64': 'package: RPM arm64'
			}

			test_a = generate_assets(a)
			test_b = generate_assets(b)

			ref_a = [
			    'adding source', {
			        'amd64': ['append str source', 'append str source']
			    }, {
			        'arm64': 'adding package: RPM arm64 source'
			    }
			]
			ref_b = {
			    'source code': 'adding source code',
			    'amd64': 'adding package: RPM arm64 source',
			    'arm64': 'adding package: RPM arm64 source'
			}

			self.assertListEqual(test_a, ref_a)
			self.assertDictEqual(test_b, ref_b)

	unittest.main()


# vim: ts=4 sw=4 noet
