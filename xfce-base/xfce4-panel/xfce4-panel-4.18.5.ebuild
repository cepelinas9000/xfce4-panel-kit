# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools vala

DESCRIPTION="Xfce's panel"
HOMEPAGE="https://gitlab.xfce.org/xfce/xfce4-panel"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/13/repository/archive.tar.bz2?sha=xfce4-panel-4.18.5 -> xfce4-panel-4.18.5.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=dev-libs/glib-2.66.0:2
	>=x11-libs/cairo-1.16.0
	>=x11-libs/gtk+-3.24.0:3[introspection?]
	>=x11-libs/libwnck-3.0:3
	>=xfce-base/exo-0.11.2
	>=xfce-base/garcon-4.17.0
	>=xfce-base/libxfce4ui-4.17.1
	>=xfce-base/libxfce4util-4.17.2[introspection?,vala?]
	>=xfce-base/xfconf-4.13.2
	dbusmenu? ( >=dev-libs/libdbusmenu-16.04.0[gtk3] )
	introspection? ( >=dev-libs/gobject-introspection-1.66:= )
	"

DEPEND="${RDEPEND}"

BDEPEND="vala? ( $(vala_depend) )
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
		$(use_enable dbusmenu dbusmenu-gtk3)
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
	xdg_desktop_database_update
}

pkg_postrm() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}