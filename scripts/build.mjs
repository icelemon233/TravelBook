import {build,context} from 'esbuild';
const options={entryPoints:['src/App.jsx'],bundle:true,outfile:'app.js',minify:true,sourcemap:false,target:['es2022'],jsx:'automatic',define:{'process.env.NODE_ENV':'"production"'},legalComments:'eof',logLevel:'info'};
if(process.argv.includes('--watch')){const ctx=await context(options);await ctx.watch();}else await build(options);
