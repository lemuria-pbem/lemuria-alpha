<?php
declare (strict_types = 1);

use Lemuria\Exception\DirectoryNotFoundException;
use Lemuria\Id;
use Lemuria\Lemuria;
use Lemuria\Test\TestConfig;
use Lemuria\Renderer\Text\TextWriter;
use Lemuria\Renderer\Text\HtmlWriter;

/**
 * Lemuria.
 */
require __DIR__ . '/../vendor/autoload.php';

$round   = 1;
$parties = ['7' => 'Erben_der_Sieben', 'lem' => 'Lemurianer', 'mw' => 'Mittwaldelben'];

try {
	Lemuria::init(new TestConfig($round));
	Lemuria::Log()->debug('Report starts.', ['timestamp' => date('r')]);
	Lemuria::load();

	$dir  = __DIR__ . '/../storage/turn';
	$turn = realpath($dir);
	if (!$turn) {
		throw new DirectoryNotFoundException($dir);
	}
	$dir = $turn . DIRECTORY_SEPARATOR . $round;
	if (!is_dir($dir)) {
		mkdir($dir);
		chmod($dir, 0775);
	}

	$reports = [];
	foreach ($parties as $i => $name) {
		$id = Id::fromId((string)$i);
		$htmlPath = $dir . DIRECTORY_SEPARATOR . $name . '.html';
		$writer   = new HtmlWriter($htmlPath);
		$writer->render($id);
		$txtPath = $dir . DIRECTORY_SEPARATOR . $name . '.txt';
		$writer  = new TextWriter($txtPath);
		$writer->render($id);
		$reports[$i] = [$htmlPath, $txtPath];
	}
} catch (Exception $e) {
	$output = (string)$e;
}

?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="de" xmlns="http://www.w3.org/1999/html">
	<head>
		<title>Lemuria-Auswertung</title>
		<link rel="stylesheet" href="/css/bootstrap.css"/>
		<link rel="stylesheet" href="/css/style.css"/>
		<script type="text/javascript" src="/js/jquery.min.js"></script>
		<script type="text/javascript" src="/js/bootstrap.bundle.min.js"></script>
		<script type="text/javascript" src="/js/script.js"></script>
	</head>
	<body>
		<?php if ($output): ?>
			<?= $output ?>
		<?php else: ?>
			<?php foreach ($parties as $id => $name): ?>
				<ul>
					<li>
						<a href="#<?= $id ?>_html"><?= str_replace('_', ' ', $name) ?> (HTML)</a>
					</li>
					<li>
						<a href="#<?= $id ?>_txt"><?= str_replace('_', ' ', $name) ?> (Text)</a>
					</li>
				</ul>
			<?php endforeach ?>
			<?php foreach ($reports as $id => $files): ?>
				<hr>
				<div id="<?= $id ?>_html">
					<?= file_get_contents($files[0]) ?>
				</div>
				<hr>
				<div id="<?= $id ?>_txt">
					<pre><?= file_get_contents($files[1]) ?></pre>
				</div>
			<?php endforeach ?>
		<?php endif ?>
	</body>
</html>