#!/bin/bash

certbot --apache -d test.lherbefollefleuriste.com
certbot --apache -d prod.lherbefollefleuriste.com
certbot --apache -d boutique.lherbefollefleuriste.com

