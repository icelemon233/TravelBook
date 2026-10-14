import React from 'react';
import {Typography} from 'antd';
const {Paragraph,Title,Text,Link}=Typography;
// A fixed set of structured local copy; no raw HTML insertion or interactive markup.
export default function RichCopy({nodes}){
 const render=(node,key)=>{
  if(typeof node==='string')return node;
  const children=node.children?.map((child,index)=>render(child,index));
  const props={key,className:node.className};
  if(node.tag==='p')return <Paragraph {...props}>{children}</Paragraph>;
  if(/^h[1-5]$/.test(node.tag))return <Title {...props} level={Number(node.tag[1])}>{children}</Title>;
  if(node.tag==='a')return <Link {...props} href={node.href} target="_blank" rel="noopener noreferrer">{children}</Link>;
  if(node.tag==='br')return <br key={key}/>;
  return <Text {...props} strong={['strong','b'].includes(node.tag)}>{children}</Text>;
 };
 return <Typography className="source-copy">{nodes.map(render)}</Typography>;
}
