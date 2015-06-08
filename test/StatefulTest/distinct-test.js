var Stateful = require('./stateful');

var initState = {
    waiting  : false,
    direction: "up"
};
var stateful = new Stateful(initState);

var waitingChange = stateful.stream.distinctUntilChanged(function(state) {
    return state.waiting;
});

waitingChange.subscribe(function(state) {
    console.log('"waiting" was changed: %s', state.waiting);
});

stateful.set({     // "waiting" was changed: true
    waiting: true
});
