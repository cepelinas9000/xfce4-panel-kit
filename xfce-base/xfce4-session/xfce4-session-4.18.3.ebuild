# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Xfce's session manager"
HOMEPAGE="https://gitlab.xfce.org/xfce/xfce4-session"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/15/repository/archive.tar.bz2?sha=xfce4-session-4.18.3 -> xfce4-session-4.18.3.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

RDEPEND=">=dev-libs/glib-2.66.0:2
	>=x11-libs/gtk+-3.24.0:3
	>=x11-libs/libwnck-3.10:3
	>=xfce-base/libxfce4ui-4.15.1
	>=xfce-base/libxfce4util-4.15.2
	>=xfce-base/xfconf-4.12.0
	>=sys-auth/polkit-0.102
	
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