// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:skillGenie/crosswordgame/maincross.dart';

import 'crossword.dart';
import 'crossgen.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'cells.dart';

class Definition extends StatefulWidget {
  Definition({ super.key, this.source, required this.index, required this.num});
  Field_Word? source;
  int index;
  int num;

  final TextStyle Definit_style = const TextStyle(
    fontSize: 20
  );

  @override
  _DefinitionState createState() => _DefinitionState();
}

class _DefinitionState extends State<Definition> {

  @override
  Widget build(BuildContext context) {
    List<DefCross> res = [];
    if (widget.source != null)
    {
      for (int i = 0; i < widget.source!.length; i++)
      {
        if (widget.source!.word.substring(i, i+1).contains(RegExp(r"[^a-zA-Zа-яА-ЯёЁ]")))
        {
          res.add( 
            DefCross(
              letter:widget.source!.word.substring(i, i+1),
              last: i == widget.source!.length - 1,
              let_ind: i,
              word_ind: widget.source!.num,
              is_const: true,
              focused: false,
              clone_ind: -1,
              clone_let_ind: -1,
            )
          );
        }
        else
        {
          String letter = widget.source!.in_word.substring(i, i+1);
          int clone_ind = -1;
          int clone_let_ind = -1;
          for (var inters in widget.source!.inters)
          {
            if (inters.source_index == i)
            {
              clone_ind = inters.word;
              clone_let_ind = inters.word_index;
              break;
            }
          }
          res.add( 
            DefCross(
              letter:widget.source!.in_word.substring(i, i+1),
              last: i == widget.source!.length - 1,
              let_ind: i,
              word_ind: widget.source!.num,
              is_const: false,
              focused: i == widget.index,
              clone_ind: clone_ind,
              clone_let_ind: clone_let_ind,
              mistake: widget.source!.mistakes.contains(i),
            )
          );
        }
        // result += ' ';
      }
    }
    return Card(
      shadowColor: Colors.white,
      margin: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(  //Номер слова
            margin: const EdgeInsets.fromLTRB(15, 10, 15, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip( 
                  label:SizedBox(
                    height: 25,
                    width: 40,
                    child: Text(
                    (widget.source==null)?'':'${widget.source!.num+1}/${widget.num}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: ColorTheme.GetTextColor(context),
                    )
                  ))
                ),
                Chip( 
                  label: SizedBox(
                    height: 25,
                    width: 40,
                    child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(
                      Icons.delete,
                      color: ColorTheme.GetTextColor(context),
                    ),
                    onPressed: () {

                      for (var a in res)
                      {
                        a.erase(context);
                      }
                    },
                  ),)

                ),
              ]
            )
          ),
          FittedBox(  //Само слово
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            child:Container(
              margin: const EdgeInsets.fromLTRB(15, 5, 15, 5),
              height: 50,
              alignment: Alignment.centerLeft,
              child: FocusTraversalGroup(
                child: Row (
                  children: res,
                )
              ),   
            ),
          ),
          const Divider(
          ),
          Container(  //Определение слова
            margin: const EdgeInsets.all(10),  //Определение слова
            child:AutoSizeText(
              (widget.source==null)?'':widget.source!.definition,
              style: widget.Definit_style,
              maxLines: 5, 
            ),
          ),
        ]
      )  
    );
  }
}

class DefCross extends StatelessWidget {  //Ячейка в определении слова
  DefCross({ super.key, required this.let_ind, required this.word_ind, required this.last, required this.letter,
            required this.is_const, required this.focused, required this.clone_ind, required this.clone_let_ind,
            this.mistake = false}); //Ячейка в определении слова

  bool mistake;
  FocusNode myFocusNode = FocusNode();
  final int let_ind;  //Индекс буквы
  final int word_ind; //Индекс слова
  final bool last;  //Является ли данная буква последней
  final bool focused;

  final int clone_ind;  //Индекс слова перекрывающей/перекрытой ячейки [-1]
  final int clone_let_ind;  //Индекс непосредственно ячейки [-1]

  bool is_const;
  
  String letter;  //Буква на этом месте

  var txt_controller = TextEditingController();

  final TextStyle Header_style = const TextStyle(
    fontSize: 30,
    fontFamily: 'Arial'
  );
  final TextStyle Header_const_style = TextStyle(
    fontSize: 30,
    fontFamily: 'TimesNewRoman',
    color: Colors.grey[400],
  );

  late CellFormatter txt_format = CellFormatter(node:myFocusNode, is_last:last);

  void erase(BuildContext context)  //Стереть содержимое ячейки
  {
    var parent = CrosswordPage.of(context);
    if (parent != null)
    {
      parent.ChangeLetter('', word_ind, let_ind);

      if (clone_ind != -1)
      {
        parent.ChangeLetter('', clone_ind, clone_let_ind); //Изменение буквы в пересечении
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var chosen_style = (is_const?Header_const_style:Header_style);
    return Container(
      height: 50,
      width: 50,
      alignment: Alignment.centerLeft,
      child: Card(
        shadowColor: Colors.white,  //Убираем тень
        elevation: 0,
        color: focused?(mistake?ColorTheme.GetHLWrongCellColor(context):ColorTheme.GetHLCellColor(context)):
              (mistake?ColorTheme.GetWrongCellColor(context):ColorTheme.GetCellColor(context)), 
        child: InkWell(
          focusNode: myFocusNode,
          onFocusChange: (bool f) {            
            if (is_const)
            {
              last?myFocusNode.unfocus():myFocusNode.nextFocus();
              return;
            }
            var parent = CrosswordPage.of(context);
            if (parent != null)
            {
              if (f) 
              {     
                parent.ChooseWord(word_ind, let_ind);
              }
              parent.ChangeFocus(f, word_ind, let_ind);
              if (clone_ind != -1)
              {
                parent.ChangeFocus(f, clone_ind, clone_let_ind); //Изменение буквы в пересечении
              }
            }
          },
          child: Center(
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Text(
                  letter,
                  style: chosen_style,
                  textAlign: TextAlign.center,
                ), 
                TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  cursorColor: (focused)?ColorTheme.GetHLCellColor(context):ColorTheme.GetCellColor(context),
                  showCursor: false,
                  textInputAction: TextInputAction.next,
                  controller: txt_controller,
                  decoration: null,
                  style: chosen_style,
                  textAlign: TextAlign.center,
                  maxLength: 2, //Extra character for next symbol
                  onChanged: (String value) {
                    var parent = CrosswordPage.of(context);
                    if (parent != null)
                    {
                      parent.ChangeLetter(value, word_ind, let_ind);

                      if (clone_ind != -1)
                      {
                        parent.ChangeLetter(value, clone_ind, clone_let_ind); //Изменение буквы в пересечении
                      }
                    }
                  },
                  inputFormatters: [
                    txt_format,
                  ],
                ),
              ],
            )   
          ) 
        )     
      )  
    );
  }
}