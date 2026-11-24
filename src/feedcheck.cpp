#include "feedcheck.h"

#include <openssl/evp.h>

QByteArray FeedCheck::feedKey()
{
    return QByteArray::fromHex(kFeedKeyHex);
}

bool FeedCheck::verify(const QByteArray &data, const QByteArray &signature, const QByteArray &publicKey)
{
    if (signature.size() != 64 || publicKey.size() != 32)
        return false;
    EVP_PKEY *key = EVP_PKEY_new_raw_public_key(EVP_PKEY_ED25519, nullptr,
                                                reinterpret_cast<const unsigned char *>(publicKey.constData()), 32);
    if (!key)
        return false;
    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    // Ed25519 signs the message itself, so there is no digest to name.
    const bool ok = ctx && EVP_DigestVerifyInit(ctx, nullptr, nullptr, nullptr, key) == 1
                    && EVP_DigestVerify(ctx, reinterpret_cast<const unsigned char *>(signature.constData()), 64,
                                        reinterpret_cast<const unsigned char *>(data.constData()), size_t(data.size()))
                           == 1;
    EVP_MD_CTX_free(ctx);
    EVP_PKEY_free(key);
    return ok;
}
