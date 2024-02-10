# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="A set of three plugins which allows putting buttons, title and menu of active or maximized windows on the panel."
HOMEPAGE="https://gitlab.xfce.org/panel-plugins/xfce4-windowck-plugin"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/754/repository/archive.tar.bz2?sha=xfce4-windowck-plugin-0.5.1 -> xfce4-windowck-plugin-0.5.1.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=x11-libs/gtk+-3.22.0:3
	>=x11-libs/libwnck-3.22:3
	>=xfce-base/libxfce4ui-4.14.0
	>=xfce-base/libxfce4util-4.14.0
	>=xfce-base/xfce4-panel-4.14.0
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