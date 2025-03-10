// Ячейки, слова из ячеек и их форматирование
// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:skillGenie/crosswordgame/crossgen.dart';
import 'crossword.dart';
import 'maincross.dart';

class Word extends StatelessWidget {
  const Word ({ Key? key, required this.hor, required this.children, required this.parent, required this.index}) : super(key: key);
  final List<Widget> children;
  final Field_Word parent;
  final int index;
  final bool hor;

  void Focus(int let_ind)
  {
    if (let_ind == -1)
    {
      return;
    }
    if (children[let_ind].runtimeType == CellCross)
    {
      CellCross child = children[let_ind] as CellCross;
      child.myFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget WordContainer;
    if (hor)
    {
      WordContainer = Row(children: children,);
    }
    else
    {
      WordContainer = Column(children: children,);
    }
    return FocusTraversalGroup(
      child: WordContainer,
    );
  }

  void ChangeLetter(String let, int index)
  {
    dynamic child = children[index];
    if (child.runtimeType == CellCross)
    {
      try
      {
        child.setText(let);
      }
      on NoSuchMethodError 
      {
        return;
      }
    }
    parent.in_word.replaceRange(index, index+1, let);
  }
  
  void ChangeFocus(bool value, int index)
  {
    dynamic child = children[index];
    if (child.runtimeType == CellCross)
    {
      try
      {
        child.setHighlighted(value);
      }
      on NoSuchMethodError 
      {
        return;
      }
    }
    // parent.highlighted = value?index:-1;
  }
}

class CellCross extends StatelessWidget {
  CellCross({ Key? key, required this.last, this.letter='A', this.pseudo_focused=false, required this.let_ind, required this.word_ind, required this.light_highlight,
    required this.mistake, this.clone_ind = -1, this.clone_let_ind = -1}) : super(key: key);
  final bool last;
  final bool mistake;
  final int let_ind;
  final int word_ind;

  final bool light_highlight;
  bool pseudo_focused;
  
  final String letter;

  final int clone_ind;
  final int clone_let_ind;

  var txt_controller = TextEditingController();

  final _biggerFont = const TextStyle(fontSize: 40);
  late CellFormatter txt_format = CellFormatter(node:myFocusNode, is_last:last);

  var myFocusNode = FocusNode();

  void setText(String let)
  {
    txt_controller.text = let;
  }

  void setHighlighted(bool value)
  {
    pseudo_focused = value;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Card(
        color: mistake?
        (pseudo_focused?ColorTheme.GetHLWrongCellColor(context):ColorTheme.GetWrongCellColor(context))
        :pseudo_focused?ColorTheme.GetHLCellColor(context):light_highlight?ColorTheme.GetLightHLCellColor(context):ColorTheme.GetCellColor(context), 
        child: InkWell(
          focusNode: myFocusNode,
          onFocusChange: (bool f) {
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
                parent.ChangeFocus(f, clone_ind, clone_let_ind);
              }
            }
          },
          child: Center(
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Text(
                  letter,
                  style: _biggerFont,
                  textAlign: TextAlign.center,
                ), 
                TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  // cursorColor: (myFocusNode.hasFocus)?sel_color:for_color,
                  showCursor: false,
                  // focusNode: myFocusNode,
                  textInputAction: TextInputAction.next,
                  controller: txt_controller,
                  decoration: null,
                  style: _biggerFont,
                  textAlign: TextAlign.center,
                  maxLength: 2, //Extra character for next symbol
                  onChanged: (String value) {
                    var parent = CrosswordPage.of(context);
                    if (parent != null)
                    {
                      parent.ChangeLetter(value, word_ind, let_ind);
                      if (clone_ind != -1)
                      {
                        parent.ChangeLetter(value, clone_ind, clone_let_ind);
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

// ReadOnlyCell
class ReadOnlyCell extends StatelessWidget {
  ReadOnlyCell({ Key? key, required this.last, this.letter='A'}) : super(key: key);
  final bool last;
  final String letter;
  final _biggerFont = const TextStyle(fontSize: 40);
  var myFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Card(
        color: ColorTheme.GetROCellColor(context), 
        child: InkWell(
          onFocusChange: (bool f) {
            if (f) {
              if (last)
              {
                myFocusNode.unfocus();
              }
              else
              {
                myFocusNode.nextFocus();
              }
            }
          },
          child: Center(
            child: Text(
              letter,
              style: _biggerFont,
            ),
          )    
        ) 
      )
    );
  }
}

class CellFormatter extends TextInputFormatter {
  CellFormatter ({ required this.node, required this.is_last});
  FocusNode node;
  final bool is_last;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue
      ) {
        if (newValue.text.contains(RegExp(r"[^a-zA-Zа-яА-ЯёЁ]")))
        {
          return const TextEditingValue();
        }
        if (newValue.text.length <= 1)
        {
          if (newValue.composing != TextRange.empty || kIsWeb || Platform.isWindows)
          {
            if (!is_last)
            {
              node.nextFocus();
            }
            else
            {
              node.unfocus();
            }
          }
          return TextEditingValue(text:newValue.text.toUpperCase());
        }
        if (newValue.text.substring(1) == oldValue.text)
        {
          if (!is_last)
            {
              node.nextFocus();
            }
            else
            {
              node.unfocus();
            }
          return TextEditingValue(text:newValue.text.substring(0,1).toUpperCase());
        }
        else
        {
          if (!is_last)
            {
              node.nextFocus();
            }
            else
            {
              node.unfocus();
            }
          return TextEditingValue(text:newValue.text.substring(1).toUpperCase());
        }
      }
}