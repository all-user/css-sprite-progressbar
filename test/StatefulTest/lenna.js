var makeStateful = require('./stateful').makeStateful;

function Player(name) {
    this.name = name;

    var initState = {
        poison  : false,
        confuse : false,
        sleep   : false,
        silence : false,
        darkness: false,
        berserk : false,
        petrify : false,
        reflect : false,
        vanish  : false,
        toad    : false,
        levitate: false
    };

    makeStateful(this, initState)
}

var lenna = new Player("lenna");

var bio = function(player) {
    player.stateful.set({
        poison: true
    });
};

lenna.stateful.stream.distinctUntilChanged(function(state) {
    return state.poison;
}).subscribe(function(state) {
    console.log('lenna was poisoned!');
});

bio(lenna); //   lenna was poisoned!
