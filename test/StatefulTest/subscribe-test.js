var Stateful = require('./stateful');

var initState = { waiting: false };
var stateful  = new Stateful(initState);

stateful.stream.subscribe(function(state) {
    console.log("state was changed: %s", state.waiting);
});

stateful.set({     // state was changed: true
    waiting: true
});
