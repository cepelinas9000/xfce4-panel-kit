# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Xfce's window manager"
HOMEPAGE="https://gitlab.xfce.org/xfce/xfwm4"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/19/repository/archive.tar.bz2?sha=xfwm4-4.18.0 -> xfwm4-4.18.0.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=x11-libs/gtk+-3.24:3
	>=x11-libs/libXinerama-1.1.4
	>=x11-libs/libwnck-3.14:3
	>=xfce-base/libxfce4util-4.12
	>=xfce-base/xfconf-4.13
	>=x11-libs/libXcomposite-0.2
	>=media-libs/libepoxy-1.0
	>=x11-libs/startup-notification-0.5
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXpresent
	x11-libs/libXcomposite
	x11-libs/libXi
	x11-libs/libXres
	"

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