function Zepto(editor, res, dbg, stdlib) {
  this.changed = true;
  this.waiting = [];
  this.code = null;
  this.result = document.getElementById(res);
  this.dbg = document.getElementById(dbg);
  this.stdlib = document.getElementById(stdlib).stdlibData;
  this.editor = editor;
  var that = this;
  editor.getSession().on("change", function() {
    that.changed = true;
    var x;
    while(x = that.waiting.pop()) x();
  });
}

Zepto.prototype.getStdlib = function() { return this.stdlib; }

Zepto.prototype.waitForChange = function(c) { if(this.changed) c(); else this.waiting.push(c); };

Zepto.prototype.getEditorContents = function() {
  this.changed = false
  return this.editor.getSession().getValue();
};

Zepto.prototype.write = function(text) {
  this.result.value = text;
}

Zepto.prototype.writeDbg = function(text) {
  this.dbg.value +=  "\n" + text;
}

var zepto;
function zeptoInit() {
  zepto = new Zepto(editor, 'result', 'dbg', 'stdlib');
  console.log = function (message) {
    zepto.writeDbg(message);
  };
}

