Burger Index: *New* city development index
================================================

Author
------------------------------------------------

[Kyeongwon Lee](https://github.com/heleeos)

Introduction
------------------------------------------------

> "한 도시의 발전 수준은 (버거킹의 개수+맥도날드의 갯수+KFC의 갯수)/롯데리아의 갯수를 계산하여 높게 나올수록 더 발전된 도시라고 할 수 있다." - 밐폭도(Twitter@RioterOfMiku)


Description
------------------------------------------------

```bash
|-- README.md                             
|-- burger.Rproj
|-- data                                  
|   |-- burger                              # burger dataset
|   |-- map                                 # Korean map shp files
|   |-- nb_sig_mat.csv                   
|   |-- pop                                 # population datasets
|   `-- shp_sig.Rdata                      
|-- docs                                    # docstrings
|   |-- beforebody.html         
|   |-- report.Rmd
|   |-- report.nb.html
|   `-- styles.css
|-- figs                                    # figures
|   |-- B_sig.pdf
|   |-- K_sig.pdf
|   |-- L_sig.pdf
|   |-- MS_sig.pdf
|   |-- M_sig.pdf
|   |-- bi_sig.pdf
|   |-- g_sig.pdf
|   `-- popden_sig.pdf
`-- src                                     # source code
    |-- data_preproc.R                      # data preprocessing
    |-- eda.R                               # EDA
    `-- plot.R                              # visualize
```

Note
------------------------------------------------

Dataset들은 저작권 문제로 git에 관리하지 않습니다. 

* `data/burger`: https://github.com/idjoopal/BurgerIndex2019
* `data/map`: http://www.gisdeveloper.co.kr/?p=2332 
* `data/pop`: [국가통계포털](http://kosis.kr/index/index.do) 의 `주제별통계/ 인구·가구/주민등록인구현황/행정구역(시군구)별, 성별 인구수` 에서 엑셀파일을 다운로드 받은 뒤 적당히 가공하면 됩니다.

전처리 및 plot관련 R코드는 [서울대학교 공간통계 연구실](http://stat.snu.ac.kr/spatstat/)의 자료를 참고하였습니다.

References
------------------------------------------------

* https://github.com/idjoopal/BurgerIndex2019
* http://blog.naver.com/prologue/PrologueList.nhn?blogId=idjoopal&parentCategoryNo=88