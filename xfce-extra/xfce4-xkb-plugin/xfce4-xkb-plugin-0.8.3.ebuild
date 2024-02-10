# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="XKB layout switching panel plug-in for the Xfce desktop environment"
HOMEPAGE="https://gitlab.xfce.org/panel-plugins/xfce4-xkb-plugin"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/76/repository/archive.tar.bz2?sha=xfce4-xkb-plugin-0.8.3 -> xfce4-xkb-plugin-0.8.3.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=gnome-base/librsvg-2.40:2
	>=x11-libs/gtk+-3.20.0:3
	>=x11-libs/libwnck-3.14:3
	>=x11-libs/libxklavier-5.3
	>=xfce-base/garcon-0.4.0
	>=xfce-base/libxfce4ui-4.12.0
	>=xfce-base/libxfce4util-4.12.0
	>=xfce-base/xfce4-panel-4.12.0
	>=xfce-base/xfconf-4.12.1
	>=x11-libs/libnotify-0.7.0"

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