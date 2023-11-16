import {GlobType, StartTemplateWithLambda} from "@atomicloud/cyan-sdk";

StartTemplateWithLambda(async (i, d) => {

  const top = await i.text("What is the top margin?");
  const bottom = await i.text("What is the bottom margin?");
  const left = await i.text("What is the left margin?");
  const right = await i.text("What is the right margin?");

  const font = await i.text("What is the font size?");
  const title = await i.text("What is the title?");
  const author = await i.text("What is the author's name?");
  const date = await i.dateSelect("What is the date?");

  const dateString = new Date(date).toLocaleDateString('en-US', { 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  })

  return {
    processors: [
      {
        name: "cyan/default",
        files: [
          {
            glob: "report.tex",
            exclude: [],
            type: GlobType.Template,
          }
        ],
        config: {
          vars: {
            top: top,
            bottom: bottom,
            left: left,
            right: right,
            font: font,
            title: title,
            author: author,
            date: dateString,
          }
        },
      },  
    ],
    plugins: [
      
    ],
  }
});
