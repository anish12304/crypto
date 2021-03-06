namespace Nuxed\Crypto\Symmetric\Encryption;

use namespace Nuxed\Crypto\{Binary, Exception};

/**
 * Unpack ciphertext for decryption.
 */
function unpack(string $ciphertext): (string, string, string, string) {
  $length = Binary\length($ciphertext);
  // Fail fast on invalid messages
  if ($length < \SODIUM_CRYPTO_GENERICHASH_BYTES) {
    throw new Exception\InvalidMessageException('Message is too short');
  }
  // The salt is used for key splitting (via HKDF)
  $salt = Binary\slice($ciphertext, 0, \SODIUM_CRYPTO_GENERICHASH_BYTES);
  // This is the nonce (we authenticated it):
  $nonce = Binary\slice(
    $ciphertext,
    // 32:
    \SODIUM_CRYPTO_GENERICHASH_BYTES,
    // 24:
    \SODIUM_CRYPTO_STREAM_NONCEBYTES,
  );
  // This is the crypto_stream_xor()ed ciphertext
  $encrypted = Binary\slice(
    $ciphertext,
    // 56:
    \SODIUM_CRYPTO_GENERICHASH_BYTES + \SODIUM_CRYPTO_STREAM_NONCEBYTES,
    // $length - 120
    $length -
      (
        \SODIUM_CRYPTO_GENERICHASH_BYTES + // 32
        \SODIUM_CRYPTO_STREAM_NONCEBYTES + // 56
        \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX // 120
      ),
  );
  // $auth is the last 32 bytes
  $auth = Binary\slice(
    $ciphertext,
    $length - \SODIUM_CRYPTO_GENERICHASH_BYTES_MAX,
  );
  // We don't need this anymore.
  \sodium_memzero(inout $ciphertext);
  // Now we return the pieces in a specific order:
  return tuple($salt, $nonce, $encrypted, $auth);
}
