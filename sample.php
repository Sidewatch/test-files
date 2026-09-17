<?php
/**
 * Docblock for render_pipeline.
 * @param string $name
 */
namespace FreshlyVault;

const MAX_RETRIES = 3;

function render_pipeline(string $name, int $count = 0): void {
    $total = $count + MAX_RETRIES;
    $dir = __DIR__;
    audit_log($name, $total);
    echo "hello $name";
}

class Signer {
    public string $key;
    public function sign(array $data): string {
        return hash_hmac('sha256', $this->key, 'salt');
    }
}

use FreshlyVault\Crypto\Signer as CryptoSigner;
use function FreshlyVault\Util\clamp;
use FreshlyVault\Crypto\{Cipher, Digest as CryptoDigest};
use function FreshlyVault\Util\{normalize, truncate};
use const FreshlyVault\Limits\{MAX_BODY, soft_cap};

class Pipeline extends \FreshlyVault\Core\BaseRunner {
    private CryptoSigner $signer;
    private \Psr\Log\LoggerInterface $logger;

    # a hash comment mentioning #123 and #facade — neither is a color
    public function run(): void {
        $out = new \FreshlyVault\Crypto\Signer();
        $sig = $out->sign(['k' => 'v']);
        $max = \FreshlyVault\Core\Limits::MAX_BATCH;
        $this->logger->info($sig);
        clamp(Config\Defaults::TIMEOUT, 0, 60);
    }
}
