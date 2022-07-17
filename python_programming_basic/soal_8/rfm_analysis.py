import pandas as pd
import numpy as np
from datetime import date

def rfm_analysis(df,cid,r,f,m,method='simple', weight=[1/4,1/4,1/2]):
    """
    Objective:
    Consumer segmentation based on a simple RFM analysis
    
    Arguments:
    - df = dataframe to segment, type pandas.DataFrame
    - cid = column name for customer unique ID
    - r = column name for recency data, column type should be numeric
    - f = column name for frequency data, column type should be numeric
    - m = column name for monetary data, column type should be numeric
    - method = {'simple' or 'fr-grid'}, default 'simple'
    - weight = list containing weight of each rfm variables, used if method = 'simple'
        expected value = [r_weight, f_weight, m_weight], default [1/4,1/4,1/2]
    
    Return: 
    Pandas.DataFrame containing customer ID, rfm rank, score, and segmentation label
    """
    df_c = df.copy() # used to check data types if error
    try:
        df = df.copy()
        df['r_rank'] = 5 - pd.qcut(df[r], q=5, labels = False)
        df['f_rank'] = pd.qcut(df[f], q=5, labels = False) + 1
        df['m_rank'] = pd.qcut(df[m], q=5, labels = False) + 1
        if(method == 'simple'):
            if(sum(weight) != 1):
                raise ValueError('Jumlah variabel weight harus 1')
            else:
                df['rfm_score'] = np.average(df[['r_rank','f_rank', 'm_rank']], weights=weight, axis=1)
                bins = [0, 1.6, 3, 4, 4.5, 5]
                names = ['Lost Customer', 'Low-value Customer', 'Medium-value Customer', 'High-value Customer', 'Top Customer']
                df['segment'] = pd.cut(df['rfm_score'], bins, labels=names)
                return df[[cid,r,'r_rank',f,'f_rank',m,'m_rank','rfm_score','segment']]
        elif(method == 'fr-grid'):
            fr_grid = [
                ['Hibernating', 'Hibernating', 'About To Sleep', 'Promising', 'New customers'],
                ['Hibernating', 'Hibernating', 'About To Sleep', 'Potential Loyalist', 'Potential Loyalist'],
                ['At Risk', 'At Risk', 'Need Attention', 'Potential Loyalist', 'Potential Loyalist'],
                ['At Risk', 'At Risk', 'Loyal Customers', 'Loyal Customers', 'Champions'],
                ["Can't Lose Them", "Can't Lose Them", 'Loyal Customers', 'Loyal Customers', 'Champions']
            ] # sometimes the dumbest method win.
            df['segment'] = df[['f_rank', 'r_rank']].apply(lambda x: fr_grid[x.f_rank - 1][x.r_rank - 1], axis = 1)
            return df[[cid,r,'r_rank',f,'f_rank','segment']]
    except:
        print('''Error. 
        Usually this is caused by datatype error. 
        Try checking your data, each data type for recency, frequency and monetary column should be numeric \n''')
        print(df_c.info())
        print('\n If not, try checking the weight, the sum of the weight should be exactly 1')
        print(weight)
        print(sum(weight))