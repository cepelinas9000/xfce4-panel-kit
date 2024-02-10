# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="A weather plugin for the Xfce desktop environment"
HOMEPAGE="https://gitlab.xfce.org/panel-plugins/xfce4-weather-plugin"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/73/repository/archive.tar.bz2?sha=xfce4-weather-plugin-0.11.1 -> xfce4-weather-plugin-0.11.1.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=dev-libs/glib-2.50.0:2
	>=dev-libs/libxml2-2.4.0:2
	>=net-libs/libsoup-2.42.0:2.4[ssl]
	>=x11-libs/gtk+-3.22.0:3
	>=xfce-base/libxfce4ui-4.12.0
	>=xfce-base/libxfce4util-4.12.0
	>=xfce-base/xfce4-panel-4.12.0
	>=xfce-base/xfconf-4.12.0
	>=sys-power/upower-0.9.0"

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
		$(use_enable upower)
		GEONAMES_USERNAME=Funtoo
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