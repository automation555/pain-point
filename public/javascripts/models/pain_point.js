(function() {
  window.PainPoint = function PainPoint(attributes) {
    this.id = attributes.id;
    this.name = attributes.name;
    this.vote_state = attributes.vote_state;
  };

  PainPoint.prototype.url = function() {
    return "/pain_points/" + this.id;
  }

  function send_vote(direction, callback) {
    var self = this;
    $.ajax({
      type: "POST",
      url: self.url() + "/" + direction,
      data: JSON.stringify({authenticity_token: window._token}),
      contentType: "application/json",
      dataType: "json",
      success: function(data) {
        self.name = data.name;
        self.vote_state = data.vote_state;
        if(callback) {
          callback(self);
        }
      }
    });
  }

  PainPoint.prototype.up_vote = function(callback) {
    send_vote.call(this, "up_vote", callback);
  }

  PainPoint.prototype.down_vote = function(callback) {
    send_vote.call(this, "down_vote", callback);
  }

  PainPoint.instances = [];
  PainPoint.sync = function(data) {
    for(var i=0; i < data.length; i++) {
      this.instances.push(new PainPoint(data[i]));
    }
  };
})();