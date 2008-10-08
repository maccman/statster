var Stats = {
  host: "locahost:3000",
  cookieName: "booYaStats",
  
  init: function(){
    var unique = true;
    if(this.hasCookie()){
      unique = false;
      this.setCookie();
    }
    this.recordHit(unique);
  },
  
  hasCookie: function(){
    return(this._readCookie(this.cookieName) ? true : false);
  },
  
  setCookie: function(){
    this._createCookie(this.cookieName, '1');
  },
  
  recordHit: function(unique){
    var img = new Image(1,1);
    img.src = 'http://' + this.host + '/stats/record?unique=' + unique;
  },
  
  // Private
  
  _createCookie: function(name, value) {
    
      var date = new Date();
      date.setTime(date.getTime()+(3600 * 1000));
      var expires = "; expires=" + date.toGMTString();
      document.cookie = name + "=" + value + expires + "; path=/";
    
  },

  _readCookie: function(name) {
  	var nameEQ = name + "=";
  	var ca = document.cookie.split(';');
  	for(var i=0;i < ca.length;i++) {
  		var c = ca[i];
  		while (c.charAt(0)==' ') c = c.substring(1,c.length);
  		if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
  	}
  	return null;
  }

}

Stats.init();