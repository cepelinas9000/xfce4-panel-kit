# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils autotools

DESCRIPTION="Modern, fast and easy-to-use file manager for Xfce"
HOMEPAGE="https://gitlab.xfce.org/xfce/thunar"
SRC_URI="https://gitlab.xfce.org/api/v4/projects/8/repository/archive.tar.bz2?sha=thunar-4.18.10 -> thunar-4.18.10.tar.bz2"

LICENSE="BSD-2 GPL-2+"
SLOT="0"
KEYWORDS="*"

IUSE="udev libnotify introspection +exif +pcre"

DEPEND=">=dev-libs/glib-2.66.0:2
	>=x11-libs/gdk-pixbuf-2.40.0:2
	>=x11-libs/gtk+-3.24.0:3
	>=x11-libs/pango-1.38.0
	>=xfce-base/exo-4.17.0
	>=xfce-base/libxfce4ui-4.17.6
	>=xfce-base/libxfce4util-4.17.2
	>=xfce-base/xfce4-panel-4.12.0
	>=xfce-base/xfconf-4.12.0
	exif? ( >=media-libs/libexif-0.6.19:= )
	introspection? ( dev-libs/gobject-introspection:= )
	libnotify? ( >=x11-libs/libnotify-0.7 )
	pcre? ( >=dev-libs/libpcre2-10.0:= )
	udisks? ( >=dev-libs/libgudev-145:= )
	"

RDEPEND="${DEPEND}
	>=dev-util/desktop-file-utils-0.20-r1
	x11-misc/shared-mime-info
	trash-panel-plugin? (
		>=gnome-base/gvfs-1.18.3
	)
	udisks? (
		>=gnome-base/gvfs-1.18.3[udisks,udev]
		virtual/udev
	)
"

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
		$(use_enable introspection)
		$(use_enable udisks gudev)
		$(use_enable libnotify notifications)
		$(use_enable exif)
		$(use_enable pcre pcre2)

	)
        econf "${myconf[@]}"
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {

	elog "If you were using an older Xfce version and Thunar fails to start"
	elog "with a message similar to:"
	elog "  Failed to register: Timeout was reached"
	elog "you may need to reset your xfce4 session:"
	elog "  rm ~/.cache/sessions/xfce4-session-*"
	elog "See https://bugs.gentoo.org/698914."

	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}