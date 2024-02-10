# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Displays remaining battery life and charge status"
HOMEPAGE="https://gitlab.xfce.org/panel-plugins/xfce4-battery-plugin"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/40/repository/archive.tar.bz2?sha=xfce4-battery-plugin-1.1.5 -> xfce4-battery-plugin-1.1.5.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=dev-libs/glib-2.28.0:2
	>=x11-libs/gtk+-3.16.0:3
	>=xfce-base/libxfce4ui-4.12.0
	>=xfce-base/libxfce4util-4.8.0
	>=xfce-base/xfce4-panel-4.12.0"

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

pkg_setup() {
    if use kernel_linux; then
	CONFIG_CHECK="~ACPI_BATTERY"
	linux-info_pkg_setup
    fi
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