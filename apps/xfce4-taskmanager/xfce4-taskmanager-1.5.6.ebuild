# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Easy to use task manager"
HOMEPAGE="https://gitlab.xfce.org/apps/xfce4-taskmanager"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/34/repository/archive.tar.bz2?sha=xfce4-taskmanager-1.5.6 -> xfce4-taskmanager-1.5.6.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=x11-libs/cairo-1.5.0
	>=x11-libs/gtk+-3.22.0:3
	>=x11-libs/libXmu-1.1.2
	>=xfce-base/libxfce4ui-4.14.0
	>=xfce-base/xfconf-4.14.0
	x11-libs/libwnck:3"

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