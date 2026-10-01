<?php
/**
 * Docblock for render_pipeline.
 * @param string $name
 */
namespace AcmeVault;

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

use AcmeVault\Crypto\Signer as CryptoSigner;
use function AcmeVault\Util\clamp;
use AcmeVault\Crypto\{Cipher, Digest as CryptoDigest};
use function AcmeVault\Util\{normalize, truncate};
use const AcmeVault\Limits\{MAX_BODY, soft_cap};

class Pipeline extends \AcmeVault\Core\BaseRunner {
    private CryptoSigner $signer;
    private \Psr\Log\LoggerInterface $logger;

    # a hash comment mentioning #123 and #facade — neither is a color
    public function run(): void {
        $out = new \AcmeVault\Crypto\Signer();
        $sig = $out->sign(['k' => 'v']);
        $max = \AcmeVault\Core\Limits::MAX_BATCH;
        $this->logger->info($sig);
        clamp(Config\Defaults::TIMEOUT, 0, 60);
    }
}
