package dev.almurajaah.al_murajaah

/** Standalone JVM regression check, compiled with the production validator. */
fun main() {
    var checks = 0
    fun expect(id: String, url: String, allowed: Boolean) {
        check(ApprovedAudioDownloads.allows(id, url) == allowed) { "Unexpected transfer decision for $id / $url" }
        checks++
    }
    for (surah in 1..114) {
        val number = surah.toString().padStart(3, '0')
        expect("zarami-hafs-$number-v1", "https://res.cloudinary.com/yw5eprsc/video/upload/zarami-$number.mp3", true)
        expect("zarami-hafs-$number-v2", "https://res.cloudinary.com/yw5eprsc/video/upload/v123/zarami-$number.mp3", true)
    }
    val origins = listOf(
        "brother-001" to "https://res.cloudinary.com/yw5eprsc/video/upload/v1791645967/E1-Nas-Hajj-end.mp3",
        "brother-002" to "https://res.cloudinary.com/yw5eprsc/video/upload/v1791645951/E2-Nas-Ibrahim-part.mp3",
        "brother-003" to "https://res.cloudinary.com/yw5eprsc/video/upload/v1791645961/E3-Nas-Nuur-part.mp3",
        "origin-004" to "https://res.cloudinary.com/yw5eprsc/video/upload/v1791645964/E4-Sh-Abdulrahman-Hajj-end.mp3",
    )
    for ((id, url) in origins) {
        expect(id, url, true)
        expect(id, url.replace("https:", "http:"), false)
        expect(id, "$url?replacement=1", false)
        expect(id, "$url/../other.mp3", false)
        expect(id, url.replace("yw5eprsc", "other"), false)
        expect(id, url.replace("v179164", "v179165"), false)
        expect(id, origins.first { it.first != id }.second, false)
        expect("../$id", url, false)
    }
    expect("brother-005", origins[0].second, false)
    expect("origin-001", origins[0].second, false)
    expect("zarami-hafs-001-v0", "https://res.cloudinary.com/yw5eprsc/video/upload/zarami-001.mp3", false)
    expect("zarami-hafs-001-v1", "https://res.cloudinary.com/yw5eprsc/video/upload/zarami-002.mp3", false)
    expect("zarami-hafs-001-v1", "https://example.com/zarami-001.mp3", false)
    expect("zarami-hafs-001-v1", "https://res.cloudinary.com/yw5eprsc/video/upload/zarami-001.mp3?x=1", false)
    println("PASS: $checks native transfer allow/reject checks")
}
