# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit bash-completion-r1 vala autotools

DESCRIPTION="D-Bus-based configuration storage system"
HOMEPAGE="https://gitlab.xfce.org/xfce/xfconf"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/17/repository/archive.tar.bz2?sha=xfconf-4.18.3 -> xfconf-4.18.3.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=dev-libs/glib-2.66.0:2
	>=xfce-base/libxfce4util-4.17.3"

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