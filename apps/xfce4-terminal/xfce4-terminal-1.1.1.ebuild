# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="A modern terminal emulator"
HOMEPAGE="https://gitlab.xfce.org/apps/xfce4-terminal"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/35/repository/archive.tar.bz2?sha=xfce4-terminal-1.1.1 -> xfce4-terminal-1.1.1.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"
IUSE="+utempter"

RDEPEND=">=dev-libs/glib-2.42.0:2
	>=x11-libs/gtk+-3.22.0:3
	>=x11-libs/vte-0.51.3:2.91
	>=xfce-base/libxfce4ui-4.16.0
	>=xfce-base/xfconf-4.16.0
	utempter? ( sys-libs/libutempter:= )
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
		--with-x
		$(use_with utempter)
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