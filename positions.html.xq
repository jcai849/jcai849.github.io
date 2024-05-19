let $cal := "https://www.calendar.auckland.ac.nz/en/courses"
let $statcal := $cal || "/faculty-of-science/statistics.html"

return
<ol class="positions">
	<li class="position">
		<div class="role">Senior Data Scientist</div>
		<div class="organisation"><a href="https://www.airnewzealand.com/">Air New Zealand</a></div>
		<div class="interval"><time>2022</time>-<time>2024</time></div>
		<p class="description">
			Versatile role involving responsibilities including:
			<ul>
				<li>Leading the re-engineer of legacy $6M/a Data Science Software</li>
				<li>Engagement with vendors of varying scale for projects valued $40K-$5M/a</li>
				<li>Business analysis and probabilistic modelling with a particular focus on Revenue Management in Air Cargo</li>
				<li>Design and implementation of new MLOps patterns, shared libraries, Data Science process improvement</li>
			</ul>
		</p>
	</li>
	<li class="position">
		<div class="role">Graduate Teaching Assistant</div>
		<div class="organisation"><a href="https://www.auckland.ac.nz/en.html">University of Auckland</a></div>
		<div class="interval"><time>2020</time>-<time>2022</time></div>
		<p class="description">
			Software development for <a href="https://lite.docker.stat.auckland.ac.nz/">iNZight Lite</a> and tutoring for the postgraduate courses <span class="course"><a href="{$statcal || '#STATS_769Advanced_Data_Science_Practice'}">STATS 769</a></span>, <span class="course"><a href="{$statcal || '#STATS_782Statistical_Computing'}">782</a></span>, and <span class="course"><a href="{$statcal || '#STATS_787Data_Visualisation'}">787</a></span>.
		</p>
	</li>
	<li class="position">
		<div class="role">Data Scientist</div>
		<div class="organisation"><a href="https://www.tonkintaylor.co.nz/">Tonkin + Taylor</a></div>
		<div class="interval"><time>2019</time></div>
		<p class="description">
			Explanatory and predictive analysis of varied datasets relating to internal and client work, involving statistical modelling and reporting.
		</p>
	</li>
	<li class="position">
		<div class="role">Teaching Assistant</div>
		<div class="organisation"><a href="https://www.auckland.ac.nz/en.html">University of Auckland</a></div>
		<div class="interval"><time>2018</time>-<time>2019</time></div>
		<p class="description">
			Tutoring undergraduate Statistics and Mathematics students in the computer laboratory, and marking for <span class="course"><a href="{$statcal || '#STATS_101'}">STATS 101</a></span>.
		</p>
	</li>
</ol>
