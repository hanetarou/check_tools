# -*- coding: utf-8 -*-
 
import sys
import re
 
def parseFile( path, result ):
  """
  status.dat をパースします
  @param path status.datのファイルパスを指定します
  @param result 結果の参照を受け取ります
  @return OKなら0です
  """
  record = {}
  mode   = ""
  parse_enabled = False
  
  try:
    f = open( path, 'r' )
  except:
    return -1
 
  for line in f.readlines():
    line = line.rstrip()
    if re.match( "^(\w+) \{$", line ):
      # 開始
      if line.find( "host" ) >= 0:
        mode = "host"
      elif line.find( "service" ) >= 0:
        mode = "service"
      elif line.find( "info" ) >= 0:
        mode = "info"
      elif line.find( "program" ) >= 0:
        mode = "program"
      else:
        continue
      record   = {}
      parse_enabled = True
      continue
    elif parse_enabled and re.match( "^\t\}$", line ):
      # 終了
      if mode == "host":
        if result.get( mode, None ) is None:
          result[ mode ] = {}
        result[ mode ][ record[ "host_name" ] ] = record.copy()
      elif mode == "service":
        if result.get( mode, None ) is None:
          result[ mode ] = {}
        if result[ mode ].get( record[ "host_name" ], None ) is None:
          result[ mode ][ record[ "host_name" ] ] = {}
        result[ mode ][ record[ "host_name" ] ][ record[ "service_description" ] ] = record.copy()
      else:
        result[ mode ] = record.copy()
      parse_enabled = False
      continue
    elif not parse_enabled:
      # パース無効
      continue
    elif re.match( "^(\s*)#", line ):
      # コメント
      continue
    elif re.match( "^\t\w", line ):
      # パースする
      pass
    else:
      # どれにも当てはまらない
      continue
    
    line = line.strip()
    data = line.split( "=", 1 )
    record[ data[0] ] = data[1]
    
  f.close()
  
  return 0
 
