# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Freedesktop.org compliant menu library"
HOMEPAGE="https://gitlab.xfce.org/xfce/garcon"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/5/repository/archive.tar.bz2?sha=garcon-4.18.1 -> garcon-4.18.1.tar.bz2"

LICENSE="LGLPL-2+ FDL-1.1+"
SLOT="0"
KEYWORDS="*"

IUSE="introspection"

RDEPEND=">=dev-libs/glib-2.66.0:2
	>=x11-libs/gtk+-3.24.0:3
	>=xfce-base/libxfce4ui-4.15.7[introspection?]
	>=xfce-base/libxfce4util-4.15.6[introspection?]
	introspection? (dev-libs/gobject-introspection )
	"

DEPEND="${RDEPEND}"

BDEPEND="
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig"

DOCS=( AUTHORS ChangeLog HACKING NEWS README.md STATUS TODO )


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
                $(use_enable introspection)
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