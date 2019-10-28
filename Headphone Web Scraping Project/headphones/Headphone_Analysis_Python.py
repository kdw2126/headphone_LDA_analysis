# -*- coding: utf-8 -*-
"""
Created on Sun Oct 27 10:56:42 2019

@author: jnaka
"""

import numpy as np
import pandas as pd

headphone_information = pd.read_csv("Headphone.csv")

headphone_information.views = headphone_information.views.replace("K", "000")
