# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools vala

DESCRIPTION="Extension library for Xfce"
HOMEPAGE="https://gitlab.xfce.org/xfce/libxfce4util"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/7/repository/archive.tar.bz2?sha=libxfce4util-4.18.1 -> libxfce4util-4.18.1.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

IUSE="+introspection vala"

REQUIRED_USE="vala? ( introspection )"

RDEPEND=">=dev-libs/glib-2.66.0:2
	  introspection? ( >=dev-libs/gobject-introspection )"

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
		$(use_enable introspection)
		$(use_enable vala)

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