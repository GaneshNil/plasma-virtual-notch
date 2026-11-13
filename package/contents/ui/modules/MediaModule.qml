import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

/*
 * MediaModule.qml
 * MPRIS media player controls, album artwork, track info and equalizer.
 */
BaseModule {
    id: mediaMod
    moduleId: "media"
    priority: 1
    preferredAccentColor: host ? host.cPink : "#ff8fd8"

    Mpris.Mpris2Model { id: mprisModel }
    readonly property var player: mprisModel.currentPlayer
    readonly property bool hasPlayer: !!player
    readonly property bool isPlaying: hasPlayer && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property string trackTitle: player ? (player.track || "") : ""
    readonly property string trackArtist: player ? (player.artist || "") : ""
    readonly property string trackAlbum: player ? (player.album || "") : ""
    readonly property var artUrl: player && player.artUrl ? player.artUrl : ""

    readonly property bool canControl: hasPlayer && player.canControl
    readonly property bool canPlay: hasPlayer && player.canPlay
    readonly property bool canPause: hasPlayer && player.canPause
    readonly property bool canGoNext: hasPlayer && player.canGoNext
    readonly property bool canGoPrevious: hasPlayer && player.canGoPrevious

    function playPause() {
        if (!player) return;
        if (isPlaying) {
            if (canPause) player.Pause();
            else if (canControl) player.PlayPause();
        } else {
            if (canPlay) player.Play();
            else if (canControl) player.PlayPause();
        }
    }

    function nextTrack() {
        if (player && canGoNext) player.Next();
    }

    function previousTrack() {
        if (player && canGoPrevious) player.Previous();
    }

    // Trigger Dynamic Island temporary activity on track changes
    onTrackTitleChanged: {
        if (trackTitle !== "" && moduleEnabled && host && host.eventQueue) {
            host.eventQueue.postEvent("media", trackTitle + (trackArtist ? " • " + trackArtist : ""), 1, 3500, preferredAccentColor);
        }
    }
}
