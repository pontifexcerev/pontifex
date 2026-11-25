/* Pontifex math: renders $...$, $$...$$, \( \) and \[ \] with KaTeX anywhere on the page.
   Used by the site and the content editor. Single $ is treated as math only when the text
   between the dollar signs looks like math, so prices such as "$500 and $600" stay as text.
   Write \$ for a literal dollar sign. */
(function(){
  var SKIP={SCRIPT:1,STYLE:1,TEXTAREA:1,INPUT:1,CODE:1,PRE:1,OPTION:1,SELECT:1};
  var RX=/\$\$([\s\S]+?)\$\$|\\\[([\s\S]+?)\\\]|\\\(([\s\S]+?)\\\)|(?<![\\$])\$([^$\n]+?)\$(?!\$)/g;
  var MATHY=/[\\^_{}]|[A-Za-z]\s*=|=\s*[A-Za-z\\(]/;
  function skipped(n){for(var p=n.parentNode;p&&p.nodeType==1;p=p.parentNode){if(SKIP[p.nodeName]||(p.classList&&(p.classList.contains('mx')||p.classList.contains('katex')))||(p.hasAttribute&&p.hasAttribute('data-nomath')))return true}return false}
  function render(tex,display,raw){
    var s=document.createElement('span');s.className=display?'mx mxd':'mx';
    try{s.innerHTML=window.katex.renderToString(tex.trim(),{displayMode:display,throwOnError:false,strict:'ignore',output:'htmlAndMathml'})}catch(e){s.textContent=raw}
    return s}
  function convert(node){
    var t=node.nodeValue;if(!t||(t.indexOf('$')<0&&t.indexOf('\\(')<0&&t.indexOf('\\[')<0))return;
    var out=document.createDocumentFragment(),last=0,m,changed=false;RX.lastIndex=0;
    while((m=RX.exec(t))){
      var tex=m[1]!==undefined?m[1]:m[2]!==undefined?m[2]:m[3]!==undefined?m[3]:m[4],display=m[1]!==undefined||m[2]!==undefined;
      if(m[4]!==undefined&&!MATHY.test(tex))continue;
      if(m.index>last)out.appendChild(document.createTextNode(t.slice(last,m.index).replace(/\\\$/g,'$')));
      out.appendChild(render(tex,display,m[0]));last=m.index+m[0].length;changed=true}
    if(!changed){if(t.indexOf('\\$')>=0)node.nodeValue=t.replace(/\\\$/g,'$');return}
    if(last<t.length)out.appendChild(document.createTextNode(t.slice(last).replace(/\\\$/g,'$')));
    node.parentNode.replaceChild(out,node)}
  function process(root){
    if(!window.katex||!root)return;
    if(root.nodeType==3){if(!skipped(root))convert(root);return}
    if(root.nodeType!=1)return;
    if(root.closest&&root.closest('.mx,.katex'))return;
    var w=document.createTreeWalker(root,NodeFilter.SHOW_TEXT,null),list=[],n;
    while((n=w.nextNode())){if(!skipped(n)&&n.nodeValue&&(n.nodeValue.indexOf('$')>=0||n.nodeValue.indexOf('\\(')>=0||n.nodeValue.indexOf('\\[')>=0))list.push(n)}
    list.forEach(convert)}
  var q=new Set(),timer=null;
  function run(){timer=null;if(!window.katex){timer=setTimeout(run,300);return}var a=Array.from(q);q.clear();a.forEach(function(n){if(n.isConnected)process(n)})}
  function sched(n){q.add(n);if(!timer)timer=setTimeout(run,30)}
  new MutationObserver(function(ms){ms.forEach(function(m){
    if(m.type=='characterData'){sched(m.target);return}
    m.addedNodes.forEach(function(n){if(n.nodeType==1||n.nodeType==3)sched(n)})})
  }).observe(document.documentElement,{childList:true,subtree:true,characterData:true});
  window.addEventListener('load',function(){sched(document.body)});
  window.renderMathIn=function(el){if(window.katex)process(el);else sched(el)};
})();
