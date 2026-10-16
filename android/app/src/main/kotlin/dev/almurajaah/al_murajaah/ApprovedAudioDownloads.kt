package dev.almurajaah.al_murajaah

/** Native transfers accept the existing catalogue rule and exact origin sources. */
internal object ApprovedAudioDownloads {
    private val origins = mapOf(
        "brother-001" to "https://res.cloudinary.com/yw5eprsc/video/upload/v1791645967/E1-Nas-Hajj-end.mp3",
        "brother-002" to "https://res.cloudinary.com/yw5eprsc/video/upload/v1791645951/E2-Nas-Ibrahim-part.mp3",
        "brother-003" to "https://res.cloudinary.com/yw5eprsc/video/upload/v1791645961/E3-Nas-Nuur-part.mp3",
        "origin-004" to "https://res.cloudinary.com/yw5eprsc/video/upload/v1791645964/E4-Sh-Abdulrahman-Hajj-end.mp3",
    )

    fun allows(id: String, url: String): Boolean {
        origins[id]?.let { return it == url }
        if (!Regex("^zarami-hafs-\\d{3}-v[1-9]\\d*$").matches(id)) return false
        val number = id.substring(12, 15)
        return Regex("^https://res\\.cloudinary\\.com/yw5eprsc/video/upload/(v[0-9]+/)?zarami-$number\\.mp3$").matches(url)
    }
}
