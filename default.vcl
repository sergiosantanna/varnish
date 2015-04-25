backend moodle {
	.host = "10.1.1.244";
	.port = "80";
}

//Ações ao receber a requisição do cliente
sub vcl_recv {

	if (req.url == "/mpc/moodle/login/index.php") {
		return (pass);
	}
	

	if (req.url ~ "view.php\?id=[0-9]+&notifyeditingon=1$") {
		return (pass);
	}

	if (req.url ~ "^/mpc/moodle/course/view.php\?id=[0-9]+$") {
		return (lookup);
	}

	if (req.url ~ "/mpc/moodle/mod/resource/view.php\?id=[0-9]+$") {
		return (lookup);
	}


	if (req.url ~ "\.(png|gif|jpg|pdf)$") {
		return (lookup);
    }


	return (pass);

}

//Hash
sub vcl_hash {

    hash_data(req.url);
    hash_data(req.http.host);

    if(req.http.Cookie ~ "MoodleSession" ) {
		set req.http.X-Varnish-Hashed-On = 
		regsub( req.http.Cookie, "^.*?MoodleSession=([^;]*);*.*$", "\1" );
    }

    if(req.url ~ "^/mpc/moodle/course/view.php\?id=[0-9]+$" && req.http.X-Varnish-Hashed-On) {
		hash_data(req.http.X-Varnish-Hashed-On);
    }


    if(req.url ~ "/mpc/moodle/mod/resource/view.php\?id=[0-9]+$" && req.http.X-Varnish-Hashed-On) { 
		hash_data(req.http.X-Varnish-Hashed-On);
    }

	return (hash);

}

//Ações ao receber as respostas do backend
sub vcl_fetch {

	if (req.url == "/mpc/moodle/login/index.php") {
		return (hit_for_pass);
	}


    if (req.url ~ "view.php\?id=[0-9]+&notifyeditingon=1$") {
		return (hit_for_pass);
    }

	if (req.url ~ "^/mpc/moodle/course/view.php\?id=[0-9]+$") {
		set beresp.ttl = 12h;
		return (deliver);
        }

	if (req.url ~ "/mpc/moodle/mod/resource/view.php\?id=[0-9]+$") {
		set beresp.ttl = 12h;
		return (deliver);
        }


    //Qualquer arquivo terminado com essas extensões ficaram em cache por 5 minutos
    if (req.url ~ "\.(png|gif|jpg|pdf)$") {       
		set beresp.ttl = 12h;
	    return (deliver);
    }

    return (hit_for_pass);
}

//Ações antes de entregar o objeto ao cliente
sub vcl_deliver {

    if (obj.hits > 0) {

        set resp.http.X-Cache = "HIT";

    } else {

        set resp.http.X-Cache = "MISS";

    }

}
