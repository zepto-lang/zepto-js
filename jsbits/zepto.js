'use strict'

let zepto = {};
zepto.stdlib = null;
zepto.stdout = console.log;
zepto.stderr = console.err;
zepto.observer = new MutationObserver(zepto.handleMutation);

zepto.registerFun = function(evaluator, env) {
  this.evaluator = evaluator;
  this.env = env;
}

zepto.eval = function(input) {
  if (!this.evaluator || this.env) {
    throw new Error("zepto is not ready yet.");
  }
  return this.evaluator(this.env, input);
}

zepto.handleMutation = function(mutations) {
  mutations.forEach(mutation => {
    nodes = Array.slice.call([], mutation.addedNodes);
    nodes.map(zepto.handleDom);
  });
}

zepto.handleDom(node) {
  if (node.nodeName != "SCRIPT" || node.type != "text/zepto")
    return null;
  return zepto.eval(node.innerHTML);
}

window.onload = function() {
  let scripts = document.getElementsByTagName("script");
  scripts = Array.slice.call([], scripts);
  scripts.map(zepto.handleDom);
}

zepto.observer.observe(document, {childList: true, subtree: true});
