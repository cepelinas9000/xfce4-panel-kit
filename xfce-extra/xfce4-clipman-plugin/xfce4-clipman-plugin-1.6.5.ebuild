# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Clipboard manager for the Xfce Panel"
HOMEPAGE="https://gitlab.xfce.org/panel-plugins/xfce4-clipman-plugin"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/42/repository/archive.tar.bz2?sha=xfce4-clipman-plugin-1.6.5 -> xfce4-clipman-plugin-1.6.5.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"
IUSE="X qrcode"

RDEPEND=">=dev-libs/glib-2.42.0:2
	>=x11-libs/gtk+-3.22.29:3
	>=x11-libs/libXtst-1.0.0
	>=x11-proto/xproto-7.0.0
	>=xfce-base/libxfce4ui-4.14.0
	>=xfce-base/libxfce4util-4.14.0
	>=xfce-base/xfce4-panel-4.14.0
	>=xfce-base/xfconf-4.14.0
	qrcode? ( >=media-gfx/qrencode-3.3.0:= )"

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
		$(use_enable X x)
		$(use_enable qrcode libqrencode)
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