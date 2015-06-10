function Zepto(editor, res, dbg, stdlib) {
  this.changed = true;
  this.waiting = [];
  this.code = null;
  this.result = document.getElementById(res);
  this.dbg = document.getElementById(dbg);
  this.stdlib = document.getElementById(stdlib).stdlibData;
  this.editor = editor;
  var that = this;
  editor.keyBinding.origOnCommandKey = editor.keyBinding.onCommandKey;
  editor.keyBinding.onCommandKey = function(e, hashId, keyCode) {
    that.changed = true;
    var x;
    while(x = that.waiting.pop()) x();
    this.origOnCommandKey(e, hashId, keyCode);
  }
  editor.keyBinding.origOnTextInput = editor.keyBinding.onTextInput;
  this.editor.keyBinding.onTextInput = function(t) {
    that.changed = true;
    var x;
    while(x = that.waiting.pop()) x();
    this.origOnTextInput(t);
  };
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

