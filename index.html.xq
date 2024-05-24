declare option db:parser "html";

<html lang="en-NZ">
<head>
	<title>Jason Cairns Curriculum Vitæ</title>
	<meta name="author" content="Jason Cairns"/>
	<link href="style.css" rel="stylesheet"/>
</head>
<body>
	<header>
		<h1>Jason Cairns Curriculum Vitæ</h1>
		<div class="last-updated">Last updated: <time>2024-05-19</time></div>
		<div class="personal">
		<div class="picture">
			<a href="jc-portrait.jpg"><img src="jc-portrait.jpg" alt="Portrait photo of Jason Cairns"/></a>
		</div>
		<div class="contact">
		<h2>Contact</h2>
			{doc('contact.html')}
		</div>
		</div>
	</header>
	<main>
		<h2>Work Experience</h2>
			{doc('positions.html')}
		<h2>Education</h2>
			<div class="institution"><a href="https://www.auckland.ac.nz/">University of Auckland</a></div>
			{doc('qualifications.html')}
			<h3>Academic Awards</h3>
				{doc('awards.html')}
		<h2>Skills</h2>
			{doc('skills.html')}
		<h2>Motivation</h2>
		<details><summary>Expand</summary>
			{doc('motivation.html')}
		</details>
		<h2>References</h2>
		<p>References available upon request</p>
	</main>
</body>
</html>
