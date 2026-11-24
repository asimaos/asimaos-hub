#pragma once

#include <QByteArray>

// Asima Hub trusts its release feed only when the feed key signed it (D39). The release step signs
// feed.json with `aosupd sign --key feed.key feed.json`, which writes feed.json.sig: a detached
// Ed25519 signature, 64 raw bytes. The feed key never signs the OS; that is the release key's job.
namespace FeedCheck {

// The feed key's public half (32 bytes, hex, as the website's `scripts/make-feed --new-key` writes it). Its fingerprint, to
// compare with what the project publishes:
// 1f33 1edc 7f0a df75 bb5c 0bb3 9fad e64e 1b08 a820 acaa 1c4d beee 1d12 ee83 f973
inline constexpr char kFeedKeyHex[] = "a062aa2aa11ae61914319dd9e039528113a9aa70b313dcedd701c564625b33fe";

// The built-in key, decoded.
QByteArray feedKey();

// True when `signature` (64 bytes) is `publicKey`'s (32 bytes) Ed25519 signature over `data`.
bool verify(const QByteArray &data, const QByteArray &signature, const QByteArray &publicKey);

} // namespace FeedCheck
