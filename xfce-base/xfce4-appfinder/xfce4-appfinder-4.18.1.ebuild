# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Application launcher and finder"
HOMEPAGE="https://gitlab.xfce.org/xfce/xfce4-appfinder"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/11/repository/archive.tar.bz2?sha=xfce4-appfinder-4.18.1 -> xfce4-appfinder-4.18.1.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=dev-libs/glib-2.66.0:2
	>=x11-libs/gtk+-3.24.0:3
	>=xfce-base/garcon-0.3.0
	>=xfce-base/libxfce4ui-4.14.0
	>=xfce-base/libxfce4util-4.15.2
	>=xfce-base/xfconf-4.14.0"

DEPEND="${RDEPEND}"

BDEPEND="
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig"

post_src_unpack() {
	if [ ! -d "${S}" ] ; then
		mv "${WORKDIR}"/${PN}-* "${S}" || die
	fi
}

src_prepare() {
	NOCONFIGURE=1 ./autogen.sh
	default
	eautoreconf
}

src_configure() {
        local myconf=(
		--enable-maintainer-mode # git source code doesn't comes with generated files, for example. glib-genmarshal only running in maintainer mode
	)
        econf "${myconf[@]}"
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}