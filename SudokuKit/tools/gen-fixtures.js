#!/usr/bin/env node
/* ============================================================
   gen-fixtures.js — 產生「JS 版真實輸出」當 Swift 移植的對照 fixture
   函式全部逐字複製自 ../../index.html 的 <script>（純邏輯函式、不碰 DOM）。
   若日後 index.html 的引擎改了，重跑此檔重生 fixture 再跑 swift test。
   用法：node gen-fixtures.js > ../Tests/SudokuKitTests/Fixtures/js-fixtures.json
   ============================================================ */
"use strict";

/* ---- 以下區塊逐字複製自 index.html（勿改）---- */
const DIFFS=[
  {key:'easy',   name:'簡單', tier:1, floor:46, sub:'空少、好上手',   color:'#22c55e'},
  {key:'medium', name:'中等', tier:1, floor:38, sub:'多一點掃描',     color:'#3b82f6'},
  {key:'hard',   name:'困難', tier:1, floor:30, sub:'要仔細掃',       color:'#f59e0b'},
  {key:'expert', name:'專家', tier:1, floor:25, sub:'空最多、最燒腦', color:'#ef4444'},
];
function mulberry32(seed){let a=seed>>>0;return function(){a|=0;a=a+0x6D2B79F5|0;
  let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}
function shuffle(arr,rng){for(let i=arr.length-1;i>0;i--){const j=Math.floor(rng()*(i+1));[arr[i],arr[j]]=[arr[j],arr[i]];}return arr;}
function levelSeed(di,lv){let h=(2166136261^di)>>>0;h=Math.imul(h^lv,16777619);h=Math.imul(h^(lv>>>8),16777619);h=Math.imul(h^(lv>>>16),16777619);return h>>>0;}
function valid(b,pos,n){
  const r=(pos/9)|0,c=pos%9;
  for(let i=0;i<9;i++){if(b[r*9+i]===n)return false;if(b[i*9+c]===n)return false;}
  const br=(r/3|0)*3,bc=(c/3|0)*3;
  for(let i=0;i<3;i++)for(let j=0;j<3;j++)if(b[(br+i)*9+(bc+j)]===n)return false;
  return true;
}
function solveFull(b,rng){
  const pos=b.indexOf(0);
  if(pos===-1)return true;
  const nums=shuffle([1,2,3,4,5,6,7,8,9],rng);
  for(const n of nums){if(valid(b,pos,n)){b[pos]=n;if(solveFull(b,rng))return true;b[pos]=0;}}
  return false;
}
function countSolutions(b,limit){
  let best=-1,bestC=null;
  for(let p=0;p<81;p++){
    if(b[p]!==0)continue;
    const cand=[];
    for(let n=1;n<=9;n++)if(valid(b,p,n))cand.push(n);
    if(cand.length===0)return 0;
    if(cand.length===1){b[p]=cand[0];const r=countSolutions(b,limit);b[p]=0;return r;}
    if(best===-1||cand.length<bestC.length){best=p;bestC=cand;}
  }
  if(best===-1)return 1;
  let count=0;
  for(const n of bestC){b[best]=n;count+=countSolutions(b,limit);b[best]=0;if(count>=limit)break;}
  return count;
}
const UNITS=(()=>{const u=[];
  for(let r=0;r<9;r++){const a=[];for(let c=0;c<9;c++)a.push(r*9+c);u.push(a);}
  for(let c=0;c<9;c++){const a=[];for(let r=0;r<9;r++)a.push(r*9+c);u.push(a);}
  for(let br=0;br<3;br++)for(let bc=0;bc<3;bc++){const a=[];
    for(let i=0;i<3;i++)for(let j=0;j<3;j++)a.push((br*3+i)*9+(bc*3+j));u.push(a);}
  return u;})();
const PEERS=(()=>{const P=[];for(let p=0;p<81;p++){const s=new Set();
  const r=(p/9|0),c=p%9,br=(r/3|0)*3,bc=(c/3|0)*3;
  for(let i=0;i<9;i++){s.add(r*9+i);s.add(i*9+c);}
  for(let i=0;i<3;i++)for(let j=0;j<3;j++)s.add((br+i)*9+(bc+j));
  s.delete(p);P.push([...s]);}return P;})();
const _pc=m=>{let n=0;while(m){m&=m-1;n++;}return n;};
const _bit=n=>1<<(n-1);
function humanSolve(puzzle,tier){
  const val=puzzle.slice(),cand=new Array(81).fill(0);
  for(let p=0;p<81;p++)if(val[p]===0){let m=0;for(let n=1;n<=9;n++)if(valid(val,p,n))m|=_bit(n);cand[p]=m;}
  const place=(p,n)=>{val[p]=n;cand[p]=0;for(const q of PEERS[p])cand[q]&=~_bit(n);};
  let prog=true;
  while(prog){
    prog=false;
    for(let p=0;p<81;p++)if(val[p]===0&&_pc(cand[p])===1){place(p,Math.log2(cand[p])+1);prog=true;}
    if(prog)continue;
    for(const u of UNITS)for(let n=1;n<=9;n++){const b=_bit(n);let w=-1,c=0;
      for(const p of u)if(val[p]===0&&(cand[p]&b)){w=p;c++;}
      if(c===1){place(w,n);prog=true;}}
    if(prog)continue;
    if(tier<2)break;
    for(let bi=18;bi<27;bi++){const box=UNITS[bi];
      for(let n=1;n<=9;n++){const b=_bit(n);const cs=box.filter(p=>val[p]===0&&(cand[p]&b));
        if(cs.length<2)continue;
        const rs=new Set(cs.map(p=>(p/9|0))),cols=new Set(cs.map(p=>p%9));
        if(rs.size===1){const r=[...rs][0];for(let c=0;c<9;c++){const q=r*9+c;
          if(!box.includes(q)&&(cand[q]&b)){cand[q]&=~b;prog=true;}}}
        if(cols.size===1){const c=[...cols][0];for(let r=0;r<9;r++){const q=r*9+c;
          if(!box.includes(q)&&(cand[q]&b)){cand[q]&=~b;prog=true;}}}}}
    if(prog)continue;
    for(let ui=0;ui<18;ui++){const u=UNITS[ui];
      for(let n=1;n<=9;n++){const b=_bit(n);const cs=u.filter(p=>val[p]===0&&(cand[p]&b));
        if(cs.length<2)continue;
        const bx=new Set(cs.map(p=>{const r=(p/9|0),c=p%9;return (r/3|0)*3+(c/3|0);}));
        if(bx.size===1){const box=UNITS[18+[...bx][0]];
          for(const q of box)if(!u.includes(q)&&val[q]===0&&(cand[q]&b)){cand[q]&=~b;prog=true;}}}}
    if(prog)continue;
    for(const u of UNITS){const em=u.filter(p=>val[p]===0);
      for(let i=0;i<em.length&&!prog;i++)for(let j=i+1;j<em.length;j++){
        const m=cand[em[i]]|cand[em[j]];
        if(_pc(cand[em[i]])<=2&&_pc(cand[em[j]])<=2&&_pc(m)===2){
          for(const p of em)if(p!==em[i]&&p!==em[j]&&(cand[p]&m)){cand[p]&=~m;prog=true;}}}
      if(prog)break;
      for(let i=0;i<em.length&&!prog;i++)for(let j=i+1;j<em.length;j++)for(let k=j+1;k<em.length;k++){
        const m=cand[em[i]]|cand[em[j]]|cand[em[k]];
        if(_pc(m)===3){for(const p of em)if(p!==em[i]&&p!==em[j]&&p!==em[k]&&(cand[p]&m)){cand[p]&=~m;prog=true;}}}
      if(prog)break;}
    if(prog)continue;
    for(const u of UNITS){for(let a=1;a<=9&&!prog;a++)for(let bb=a+1;bb<=9;bb++){
      const ba=_bit(a),b2=_bit(bb);
      const ca=u.filter(p=>val[p]===0&&(cand[p]&ba)),cb=u.filter(p=>val[p]===0&&(cand[p]&b2));
      if(ca.length===2&&cb.length===2&&ca[0]===cb[0]&&ca[1]===cb[1]){
        const keep=ba|b2;for(const p of ca)if(cand[p]&~keep){cand[p]&=keep;prog=true;}}}
      if(prog)break;}
  }
  return val.every(x=>x!==0);
}
function generate(di,seedNum){
  const rng=mulberry32(seedNum);
  const solution=new Array(81).fill(0);
  solveFull(solution,rng);
  const puzzle=solution.slice();
  const {tier,floor}=DIFFS[di];
  const order=shuffle([...Array(81).keys()],rng);
  let clues=81;
  for(const pos of order){
    if(clues<=floor)break;
    const bak=puzzle[pos];
    if(bak===0)continue;
    puzzle[pos]=0;
    const test=puzzle.slice();
    if(countSolutions(test,2)!==1||!humanSolve(puzzle,tier)){puzzle[pos]=bak;}else{clues--;}
  }
  return {puzzle,solution};
}
/* ---- 複製區塊結束 ---- */

/* ---- 產 fixture ---- */
// 1) RNG 原始整數序列：mulberry32 內部 (t^t>>>14)>>>0（除以 2^32 前的整數），做 bit-for-bit 比對
function rngUintSeq(seed, count){
  let a = seed >>> 0;
  const out = [];
  for(let k=0;k<count;k++){
    a |= 0; a = a + 0x6D2B79F5 | 0;
    let t = Math.imul(a ^ a >>> 15, 1 | a);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    out.push((t ^ t >>> 14) >>> 0);
  }
  return out;
}
// 2) rng() double 序列（前幾個），驗證浮點也一致
function rngDoubleSeq(seed, count){
  const rng = mulberry32(seed);
  const out = [];
  for(let k=0;k<count;k++) out.push(rng());
  return out;
}

const rngSeeds = [0, 1, 42, 12345, 2166136261, 3735928559, 999999999];
const rngTests = rngSeeds.map(s => ({
  seed: s >>> 0,
  uints: rngUintSeq(s, 16),
  doubles: rngDoubleSeq(s, 8),
}));

// 3) levelSeed 對照
const levelSeedTests = [];
for(let di=0; di<4; di++)
  for(const lv of [1,2,3,5,10,17,42,100,255,256,257,1000])
    levelSeedTests.push({di, lv, seed: levelSeed(di, lv)});

// 4) 闖關題目對照：四難度 × 關卡 1..10
const levelPuzzles = [];
for(let di=0; di<4; di++)
  for(let lv=1; lv<=10; lv++){
    const seed = levelSeed(di, lv);
    const {puzzle, solution} = generate(di, seed);
    levelPuzzles.push({di, lv, seed, puzzle, solution, clues: puzzle.filter(x=>x!==0).length});
  }

// 5) 無限模式題目對照：固定 seed 抽樣
const infinitePuzzles = [];
for(let di=0; di<4; di++)
  for(const seed of [1, 42, 123456, 999999999, 2863311530]){
    const {puzzle, solution} = generate(di, seed >>> 0);
    infinitePuzzles.push({di, seed: seed>>>0, puzzle, solution, clues: puzzle.filter(x=>x!==0).length});
  }

process.stdout.write(JSON.stringify({
  meta:{ generated:new Date().toISOString(), source:'index.html <script> (verbatim)', node:process.version },
  diffs: DIFFS.map(d=>({key:d.key, tier:d.tier, floor:d.floor})),
  rngTests, levelSeedTests, levelPuzzles, infinitePuzzles,
}, null, 1));
