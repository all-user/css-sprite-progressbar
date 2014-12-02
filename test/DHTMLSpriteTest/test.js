(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var DHMTLSprite;

DHMTLSprite = require('../util/DHTMLSprite');

document.addEventListener('DOMContentLoaded', function() {
  var options, sprite1, sprite2;
  console.log('start');
  options = {
    images: 'cogs.png',
    imagesWidth: 256,
    width: 64,
    height: 64,
    drawTarget: document.querySelector('#draw-target')
  };
  sprite1 = DHMTLSprite(options);
  sprite2 = DHMTLSprite(options);
  sprite2.changeImage(5);
  sprite1.draw(64, 64);
  return sprite2.draw(352, 192);
});


},{"../util/DHTMLSprite":2}],2:[function(require,module,exports){
var DHTMLSprite;

DHTMLSprite = function(options) {
  var eleStyle, element, height, imagesWidth, sprite, width;
  width = options.width, height = options.height, imagesWidth = options.imagesWidth;
  element = document.createElement('div');
  options.drawTarget.appendChild(element);
  eleStyle = element.style;
  element.style.position = 'absolute';
  element.style.width = "" + width + "px";
  element.style.height = "" + height + "px";
  element.style.backgroundImage = "url(" + options.images + ")";
  return sprite = {
    draw: function(x, y) {
      eleStyle.left = "" + x + "px";
      return eleStyle.top = "" + y + "px";
    },
    changeImage: function(index) {
      var hOffset, vOffset;
      index *= width;
      vOffset = -(index / imagesWidth | 0) * height;
      hOffset = -index % imagesWidth;
      return eleStyle.backgroundPosition = "" + hOffset + "px " + vOffset + "px";
    },
    show: function() {
      return eleStyle.display = 'block';
    },
    hide: function() {
      return eleStyle.display = 'none';
    },
    destroy: function() {
      return eleStyle.remove();
    }
  };
};

module.exports = DHTMLSprite;


},{}]},{},[1]);
