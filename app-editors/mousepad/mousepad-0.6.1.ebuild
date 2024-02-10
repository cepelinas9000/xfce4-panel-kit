# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="A simple text editor for Xfce"
HOMEPAGE="https://gitlab.xfce.org/apps/mousepad"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/22/repository/archive.tar.bz2?sha=mousepad-0.6.1 -> mousepad-0.6.1.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

IUSE="xfce"

RDEPEND=">=dev-libs/glib-2.52.0:2
	>=x11-libs/gtk+-3.22.0:3
	x11-libs/gtksourceview:4.0
	xfce? ( >=xfce-base/libxfce4ui-4.17.5 )
	>=app-text/gspell-1.6.0
	"

DEPEND="${RDEPEND}"

BDEPEND="
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig
	"

post_src_unpack() {
	if [ ! -d "${S}" ] ; then
		mv "${WORKDIR}"/${PN}-* "${S}" || die
	fi
}

src_configure() {
        local myconf=(
		--enable-maintainer-mode # git source code doesn't comes with generated files, for example. glib-genmarshal only running in maintainer mode
		--enable-gtksourceview4
		$(use_enable xfce xfce)
		)

	if ! use xfce; then
	  myconf+=( --disable-shortcuts )
	fi

        econf "${myconf[@]}"
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