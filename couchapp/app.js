var couchapp = require('couchapp');
var path = require('path');

var ddoc = { _id:'_design/app' };

ddoc.validate_doc_update = function (newDoc, oldDoc, userCtx) {   
  if (newDoc._deleted === true && userCtx.roles.indexOf('_admin') === -1) {
    throw "Only admin can delete documents on this database.";
  } 
};

ddoc.filters = {
  unseen: function(doc, req) {
    var i;

    if(doc._deleted || !doc.server) {
      return false;
    }

    if(!doc.clientsSeen || !doc.clientsSeen.length) {
      return true;
    }

    if(!req.query || !req.query.client) {
      return true;
    }

    for(i in doc.clientsSeen) {
      if(doc.clientsSeen.hasOwnProperty(i) && doc.clientsSeen[i] == req.query.client) {
        return false;
      }
    }

    return true;
  }
};

ddoc.views = {};

ddoc.views.clientsSeenCount = {};
ddoc.views.clientsSeenCount.map = function(doc) {
  if(doc.clientsSeen) {
    emit('_total', null);

    doc.clientsSeen.forEach(function(client) {
      emit(client, null);
    });
  }
};
ddoc.views.clientsSeenCount.reduce = '_count';

module.exports = ddoc;
