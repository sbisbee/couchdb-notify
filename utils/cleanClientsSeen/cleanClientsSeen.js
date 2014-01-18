var fs = require('fs');
var sag = require('sag');

var prefs = fs.readFileSync('/home/sbisbee/.couchdb-notify');
prefs = JSON.parse(prefs);

if(prefs.server.proto === 'https') {
  couch = sag.server(prefs.server.host, '443', true);
}
else {
  console.log('WARNING! Not using SSL. Exiting.');
  process.exit(1);
}

couch.setDatabase(prefs.server.db);

couch.login({
  user: prefs.server.user,
  pass: prefs.server.pass
});

couch.get({
  url: '/_design/app/_view/dupeClientSeen?include_docs=true&stale=ok',
  callback: function(resp, succ) {
    var upload = [];

    console.log('resp');

    if(!succ) {
      console.log('Error getting view', resp);
      process.exit(1);
    }

    if(!resp.body.rows || resp.body.rows.length < 1) {
      console.log('No docs');
    }
    else {
      resp.body.rows.forEach(function(row, key) {
        var doc = row.doc;

        console.log(key);

        doc.clientsSeen = doc.clientsSeen.filter(function(val, i, arr) {
          return arr.indexOf(val) == i;
        });

        upload.push(doc);
      });

      console.log('bulking up');

      couch.bulk({
        docs: upload,
        callback: function(resp, succ) {
          console.log(resp);
        }
      });
    }
  }
});
