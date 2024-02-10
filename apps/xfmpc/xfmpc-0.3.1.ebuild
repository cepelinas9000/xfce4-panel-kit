# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools vala

DESCRIPTION="MPD client written in GTK+"
HOMEPAGE="https://gitlab.xfce.org/apps/xfmpc"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/39/repository/archive.tar.bz2?sha=xfmpc-0.3.1 -> xfmpc-0.3.1.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"


DOCS=( AUTHORS ChangeLog IDEAS NEWS README THANKS )

RDEPEND=">=dev-libs/glib-2.18.0:2
	>=media-libs/libmpd-0.15.0
	>=x11-libs/gtk+-3.22.0:3
	>=xfce-base/libxfce4ui-4.12.0[vala]
	>=xfce-base/libxfce4util-4.12.0[vala]"

DEPEND="${RDEPEND}"

BDEPEND="
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig
	$(vala_depend)"

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
		
	)
	vala_src_prepare
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